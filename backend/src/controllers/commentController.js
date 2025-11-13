const pool = require("../config/db");

exports.addComment = async (req, res, next) => {
  try {
    const taskId = req.params.taskId;
    const { content } = req.body;
    const [result] = await pool.query(
      "INSERT INTO comments (task_id, user_id, content) VALUES (?, ?, ?)",
      [taskId, req.user.id, content]
    );
    const [[comment]] = await pool.query(
      `SELECT c.id, c.content, c.created_at, u.id AS user_id, u.name, u.avatar
       FROM comments c
       JOIN users u ON u.id = c.user_id
       WHERE c.id = ?`,
      [result.insertId]
    );
    res.status(201).json({ success: true, data: comment });
  } catch (error) {
    next(error);
  }
};

exports.deleteComment = async (req, res, next) => {
  try {
    const commentId = req.params.commentId;
    await pool.query("DELETE FROM comments WHERE id = ? AND user_id = ?", [
      commentId,
      req.user.id,
    ]);
    res.json({ success: true, message: "Comment removed" });
  } catch (error) {
    next(error);
  }
};
