const express = require("express");
const { body } = require("express-validator");
const taskController = require("../controllers/taskController");
const commentController = require("../controllers/commentController");
const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

router.use(authMiddleware);

router.get("/", taskController.listTasksForUser);
router.post(
  "/",
  [
    body("title").trim().isLength({ min: 2 }).withMessage("Title is required"),
    body("team_id").isInt().withMessage("team_id must be provided"),
    body("assigned_to").isInt().withMessage("assigned_to must be provided"),
  ],
  taskController.createTask
);
router.get("/:taskId", taskController.getTaskById);
router.put("/:taskId", taskController.updateTask);
router.delete("/:taskId", taskController.deleteTask);
router.post("/:taskId/remind", taskController.sendReminder);

router.post(
  "/:taskId/comments",
  [body("content").notEmpty().withMessage("Content required")],
  commentController.addComment
);
router.delete("/:taskId/comments/:commentId", commentController.deleteComment);

module.exports = router;
