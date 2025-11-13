const express = require("express");
const { body } = require("express-validator");
const userController = require("../controllers/userController");
const authMiddleware = require("../middleware/authMiddleware");
const upload = require("../middleware/uploadMiddleware");

const router = express.Router();

// Public routes (no auth required)
router.get("/search", userController.searchUsers);

// Protected routes (auth required)
router.get("/", authMiddleware, userController.listUsers);
router.get("/:id", authMiddleware, userController.getUserById);
router.put(
  "/me",
  authMiddleware,
  [
    body("name")
      .optional()
      .isLength({ min: 2 })
      .withMessage("Name must be at least 2 characters"),
  ],
  userController.updateProfile
);

router.post(
  "/me/avatar",
  authMiddleware,
  upload.single("avatar"),
  userController.uploadAvatar
);

router.put(
  "/me/password",
  authMiddleware,
  [
    body("currentPassword")
      .notEmpty()
      .withMessage("Current password is required"),
    body("newPassword")
      .isLength({ min: 6 })
      .withMessage("New password must be at least 6 characters"),
  ],
  userController.changePassword
);

module.exports = router;
