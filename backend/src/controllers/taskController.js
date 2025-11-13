const pool = require("../config/db");

exports.listTasksForUser = async (req, res, next) => {
  try {
    const [tasks] = await pool.query(
      `SELECT tasks.*, teams.name AS team_name, users.name AS assignee_name
       FROM tasks
       LEFT JOIN teams ON teams.id = tasks.team_id
       LEFT JOIN users ON users.id = tasks.assigned_to
       WHERE tasks.assigned_to = ? OR tasks.team_id IN (SELECT team_id FROM team_members WHERE user_id = ?)
       ORDER BY tasks.deadline ASC`,
      [req.user.id, req.user.id]
    );
    res.json({ success: true, data: tasks });
  } catch (error) {
    next(error);
  }
};

exports.createTask = async (req, res, next) => {
  try {
    const { title, description, deadline, status, assigned_to, team_id } =
      req.body;

    // Check if user is leader of the team
    const [[membership]] = await pool.query(
      "SELECT role FROM team_members WHERE team_id = ? AND user_id = ?",
      [team_id, req.user.id]
    );

    if (
      !membership ||
      (membership.role !== "leader" && membership.role !== "owner")
    ) {
      return res.status(403).json({
        success: false,
        message: "Only team leader can create and assign tasks",
      });
    }

    const [result] = await pool.query(
      "INSERT INTO tasks (title, description, deadline, status, assigned_to, team_id, created_by) VALUES (?, ?, ?, ?, ?, ?, ?)",
      [
        title,
        description,
        deadline,
        status || "todo",
        assigned_to,
        team_id,
        req.user.id,
      ]
    );
    res.status(201).json({ success: true, data: { id: result.insertId } });
  } catch (error) {
    next(error);
  }
};

exports.updateTask = async (req, res, next) => {
  try {
    const taskId = req.params.taskId;
    const { title, description, deadline, status, assigned_to } = req.body;

    // Get current task info
    const [[task]] = await pool.query("SELECT * FROM tasks WHERE id = ?", [
      taskId,
    ]);

    if (!task) {
      return res
        .status(404)
        .json({ success: false, message: "Task not found" });
    }

    // Check permissions
    const [[membership]] = await pool.query(
      "SELECT role FROM team_members WHERE team_id = ? AND user_id = ?",
      [task.team_id, req.user.id]
    );

    const isLeader =
      membership &&
      (membership.role === "leader" || membership.role === "owner");
    const isAssignee = task.assigned_to === req.user.id;
    const isCreator = task.created_by === req.user.id;

    // Check basic permission
    if (!isLeader && !isAssignee && !isCreator) {
      return res.status(403).json({
        success: false,
        message: "You don't have permission to update this task",
      });
    }

    // Determine which fields are being sent (not comparing values)
    const fieldsToUpdate = [];
    if (title !== undefined) fieldsToUpdate.push("title");
    if (description !== undefined) fieldsToUpdate.push("description");
    if (deadline !== undefined) fieldsToUpdate.push("deadline");
    if (assigned_to !== undefined) fieldsToUpdate.push("assigned_to");

    // If member is trying to change fields other than status, deny
    if (fieldsToUpdate.length > 0 && !isLeader && !isCreator) {
      return res.status(403).json({
        success: false,
        message: "Members can only update task status",
      });
    }

    // Build update query dynamically
    const updates = [];
    const values = [];

    if (title !== undefined) {
      updates.push("title = ?");
      values.push(title);
    }
    if (description !== undefined) {
      updates.push("description = ?");
      values.push(description);
    }
    if (deadline !== undefined) {
      updates.push("deadline = ?");
      values.push(deadline);
    }
    if (status !== undefined) {
      updates.push("status = ?");
      values.push(status);
    }
    if (assigned_to !== undefined) {
      updates.push("assigned_to = ?");
      values.push(assigned_to);
    }

    if (updates.length === 0) {
      return res.json({ success: true, message: "No changes to update" });
    }

    values.push(taskId);
    await pool.query(
      `UPDATE tasks SET ${updates.join(", ")} WHERE id = ?`,
      values
    );

    // If member completed task, notify leader
    if (status === "done" && !isLeader && isAssignee) {
      // Get task info first
      const [[taskInfo]] = await pool.query(
        "SELECT title, team_id, created_by FROM tasks WHERE id = ?",
        [taskId]
      );

      // Get team leaders (excluding current user)
      const [leaders] = await pool.query(
        `SELECT DISTINCT u.id, u.name
         FROM team_members tm
         JOIN users u ON u.id = tm.user_id
         WHERE tm.team_id = ? AND (tm.role = 'leader' OR tm.role = 'owner')
         AND u.id != ?`,
        [taskInfo.team_id, req.user.id]
      );

      // Also add task creator if not already in leaders list
      if (taskInfo.created_by !== req.user.id) {
        const [[creator]] = await pool.query(
          "SELECT id, name FROM users WHERE id = ?",
          [taskInfo.created_by]
        );
        if (creator && !leaders.find((l) => l.id === creator.id)) {
          leaders.push(creator);
        }
      }

      // Get member name
      const [[member]] = await pool.query(
        "SELECT name FROM users WHERE id = ?",
        [req.user.id]
      );

      // Create notification for each leader/creator
      for (const leader of leaders) {
        await pool.query(
          `INSERT INTO notifications (user_id, task_id, type, title, message) 
           VALUES (?, ?, 'task_completed', ?, ?)`,
          [
            leader.id,
            taskId,
            "✅ Task đã hoàn thành!",
            `${member.name} đã hoàn thành task "${taskInfo.title}"`,
          ]
        );
      }

      console.log(
        `[NOTIFICATION] Created ${leaders.length} notifications for task completion`
      );
    }

    res.json({ success: true, message: "Task updated" });
  } catch (error) {
    next(error);
  }
};

exports.deleteTask = async (req, res, next) => {
  try {
    const taskId = req.params.taskId;
    await pool.query("DELETE FROM tasks WHERE id = ?", [taskId]);
    res.json({ success: true, message: "Task deleted" });
  } catch (error) {
    next(error);
  }
};

exports.getTaskById = async (req, res, next) => {
  try {
    const taskId = req.params.taskId;
    const [[task]] = await pool.query(
      `SELECT tasks.*, 
              teams.name AS team_name,
              assignee.name AS assignee_name,
              assignee.email AS assignee_email,
              assignee.avatar AS assignee_avatar,
              creator.name AS creator_name,
              creator.email AS creator_email,
              creator.avatar AS creator_avatar
       FROM tasks
       LEFT JOIN teams ON teams.id = tasks.team_id
       LEFT JOIN users assignee ON assignee.id = tasks.assigned_to
       LEFT JOIN users creator ON creator.id = tasks.created_by
       WHERE tasks.id = ?`,
      [taskId]
    );
    if (!task) {
      return res
        .status(404)
        .json({ success: false, message: "Task not found" });
    }

    const [comments] = await pool.query(
      `SELECT c.id, c.content, c.created_at, u.id AS user_id, u.name, u.avatar
       FROM comments c
       JOIN users u ON u.id = c.user_id
       WHERE c.task_id = ?
       ORDER BY c.created_at ASC`,
      [taskId]
    );

    res.json({ success: true, data: { ...task, comments } });
  } catch (error) {
    next(error);
  }
};

exports.sendReminder = async (req, res, next) => {
  try {
    const { taskId } = req.params;

    // Get task info
    const [[task]] = await pool.query(
      `SELECT tasks.*, teams.name AS team_name, 
              assignee.name AS assignee_name, assignee.id AS assignee_id
       FROM tasks
       LEFT JOIN teams ON teams.id = tasks.team_id
       LEFT JOIN users assignee ON assignee.id = tasks.assigned_to
       WHERE tasks.id = ?`,
      [taskId]
    );

    if (!task) {
      return res
        .status(404)
        .json({ success: false, message: "Task not found" });
    }

    // Check if requester is the creator of the task
    if (task.created_by !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: "Only task creator can send reminders",
      });
    }

    // Create notification for assignee
    if (task.assignee_id) {
      await pool.query(
        `INSERT INTO notifications (user_id, task_id, type, title, message) 
         VALUES (?, ?, 'task_reminder', ?, ?)`,
        [
          task.assignee_id,
          taskId,
          "⏰ Nhắc nhở từ Leader",
          `Leader nhắc bạn cập nhật tiến độ task "${task.title}"`,
        ]
      );
    }

    res.json({
      success: true,
      message: `Reminder sent to ${task.assignee_name}`,
    });
  } catch (error) {
    next(error);
  }
};
