const pool = require("../config/db");

exports.createTeam = async (req, res, next) => {
  try {
    const { name, description } = req.body;
    const [teamResult] = await pool.query(
      "INSERT INTO teams (name, description, owner_id) VALUES (?, ?, ?)",
      [name, description, req.user.id]
    );
    const teamId = teamResult.insertId;
    await pool.query(
      "INSERT INTO team_members (team_id, user_id, role) VALUES (?, ?, ?)",
      [teamId, req.user.id, "leader"]
    );
    res
      .status(201)
      .json({ success: true, data: { id: teamId, name, description } });
  } catch (error) {
    next(error);
  }
};

exports.listTeams = async (req, res, next) => {
  try {
    const [teams] = await pool.query(
      `SELECT t.id, t.name, t.description,
              SUM(CASE WHEN tasks.status = 'done' THEN 1 ELSE 0 END) AS completed_tasks,
              COUNT(tasks.id) AS total_tasks
       FROM teams t
       JOIN team_members tm ON tm.team_id = t.id AND tm.user_id = ?
       LEFT JOIN tasks ON tasks.team_id = t.id
       GROUP BY t.id
       ORDER BY t.name`,
      [req.user.id]
    );

    // Fetch members for each team
    const teamsWithMembers = await Promise.all(
      teams.map(async (team) => {
        const [members] = await pool.query(
          `SELECT u.id, u.user_id, u.name, u.email, u.avatar, tm.role
           FROM team_members tm
           JOIN users u ON u.id = tm.user_id
           WHERE tm.team_id = ?`,
          [team.id]
        );

        return {
          ...team,
          members,
          progress:
            team.total_tasks > 0
              ? Math.round((team.completed_tasks / team.total_tasks) * 100)
              : 0,
        };
      })
    );

    res.json({
      success: true,
      data: teamsWithMembers,
    });
  } catch (error) {
    next(error);
  }
};

exports.addMemberByEmail = async (req, res, next) => {
  try {
    const { email } = req.body;
    const teamId = req.params.teamId;

    const [users] = await pool.query("SELECT id FROM users WHERE email = ?", [
      email,
    ]);
    if (users.length === 0) {
      return res
        .status(404)
        .json({ success: false, message: "User not found" });
    }

    const userId = users[0].id;

    await pool.query(
      "INSERT IGNORE INTO team_members (team_id, user_id, role) VALUES (?, ?, ?)",
      [teamId, userId, "member"]
    );
    res.json({ success: true, message: "Member invited" });
  } catch (error) {
    next(error);
  }
};

exports.getTeamDetails = async (req, res, next) => {
  try {
    const teamId = req.params.teamId;
    const [[team]] = await pool.query(
      "SELECT id, name, description FROM teams WHERE id = ?",
      [teamId]
    );
    if (!team) {
      return res
        .status(404)
        .json({ success: false, message: "Team not found" });
    }

    const [members] = await pool.query(
      `SELECT u.id, u.user_id, u.name, u.email, u.avatar, tm.role
       FROM team_members tm
       JOIN users u ON u.id = tm.user_id
       WHERE tm.team_id = ?`,
      [teamId]
    );

    const [tasks] = await pool.query(
      "SELECT id, title, status, deadline FROM tasks WHERE team_id = ? ORDER BY (deadline IS NULL), deadline ASC",
      [teamId]
    );

    res.json({ success: true, data: { ...team, members, tasks } });
  } catch (error) {
    next(error);
  }
};

exports.transferLeadership = async (req, res, next) => {
  try {
    const teamId = req.params.teamId;
    const { newLeaderId } = req.body;

    // Check if current user is leader
    const [[currentMember]] = await pool.query(
      "SELECT role FROM team_members WHERE team_id = ? AND user_id = ?",
      [teamId, req.user.id]
    );

    if (
      !currentMember ||
      (currentMember.role !== "leader" && currentMember.role !== "owner")
    ) {
      return res.status(403).json({
        success: false,
        message: "Only team leader can transfer leadership",
      });
    }

    // Check if new leader is member of team
    const [[newMember]] = await pool.query(
      "SELECT user_id FROM team_members WHERE team_id = ? AND user_id = ?",
      [teamId, newLeaderId]
    );

    if (!newMember) {
      return res.status(404).json({
        success: false,
        message: "New leader must be a team member",
      });
    }

    // Transfer leadership
    await pool.query(
      "UPDATE team_members SET role = 'member' WHERE team_id = ? AND user_id = ?",
      [teamId, req.user.id]
    );

    await pool.query(
      "UPDATE team_members SET role = 'leader' WHERE team_id = ? AND user_id = ?",
      [teamId, newLeaderId]
    );

    // Update team owner
    await pool.query("UPDATE teams SET owner_id = ? WHERE id = ?", [
      newLeaderId,
      teamId,
    ]);

    res.json({ success: true, message: "Leadership transferred successfully" });
  } catch (error) {
    next(error);
  }
};

exports.updateTeam = async (req, res, next) => {
  try {
    const teamId = req.params.teamId;
    const { name, description } = req.body;

    // Check if user is leader
    const [[membership]] = await pool.query(
      "SELECT role FROM team_members WHERE team_id = ? AND user_id = ?",
      [teamId, req.user.id]
    );

    if (
      !membership ||
      (membership.role !== "leader" && membership.role !== "owner")
    ) {
      return res.status(403).json({
        success: false,
        message: "Only team leader can update team",
      });
    }

    await pool.query(
      "UPDATE teams SET name = ?, description = ? WHERE id = ?",
      [name, description, teamId]
    );

    res.json({ success: true, message: "Team updated successfully" });
  } catch (error) {
    next(error);
  }
};

exports.deleteTeam = async (req, res, next) => {
  try {
    const teamId = req.params.teamId;

    // Check if user is leader
    const [[membership]] = await pool.query(
      "SELECT role FROM team_members WHERE team_id = ? AND user_id = ?",
      [teamId, req.user.id]
    );

    if (
      !membership ||
      (membership.role !== "leader" && membership.role !== "owner")
    ) {
      return res.status(403).json({
        success: false,
        message: "Only team leader can delete team",
      });
    }

    await pool.query("DELETE FROM teams WHERE id = ?", [teamId]);

    res.json({ success: true, message: "Team deleted successfully" });
  } catch (error) {
    next(error);
  }
};

exports.removeMember = async (req, res, next) => {
  try {
    const teamId = req.params.teamId;
    const { userId } = req.body;

    // Check if current user is leader
    const [[currentMember]] = await pool.query(
      "SELECT role FROM team_members WHERE team_id = ? AND user_id = ?",
      [teamId, req.user.id]
    );

    if (
      !currentMember ||
      (currentMember.role !== "leader" && currentMember.role !== "owner")
    ) {
      return res.status(403).json({
        success: false,
        message: "Only team leader can remove members",
      });
    }

    // Check if trying to remove leader
    const [[targetMember]] = await pool.query(
      "SELECT role FROM team_members WHERE team_id = ? AND user_id = ?",
      [teamId, userId]
    );

    if (
      targetMember &&
      (targetMember.role === "leader" || targetMember.role === "owner")
    ) {
      return res.status(403).json({
        success: false,
        message: "Cannot remove team leader",
      });
    }

    await pool.query(
      "DELETE FROM team_members WHERE team_id = ? AND user_id = ?",
      [teamId, userId]
    );

    res.json({ success: true, message: "Member removed successfully" });
  } catch (error) {
    next(error);
  }
};

exports.leaveTeam = async (req, res, next) => {
  try {
    const teamId = req.params.teamId;

    // Check if user is member of team
    const [[membership]] = await pool.query(
      "SELECT role FROM team_members WHERE team_id = ? AND user_id = ?",
      [teamId, req.user.id]
    );

    if (!membership) {
      return res.status(404).json({
        success: false,
        message: "You are not a member of this team",
      });
    }

    // Cannot leave if you are the leader
    if (membership.role === "leader" || membership.role === "owner") {
      return res.status(403).json({
        success: false,
        message: "Team leader must transfer leadership before leaving",
      });
    }

    await pool.query(
      "DELETE FROM team_members WHERE team_id = ? AND user_id = ?",
      [teamId, req.user.id]
    );

    res.json({ success: true, message: "Left team successfully" });
  } catch (error) {
    next(error);
  }
};
