const express = require("express");
const { body } = require("express-validator");
const authController = require("../controllers/authController");
const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

router.post(
  "/register",
  [
    body("name").trim().isLength({ min: 2 }).withMessage("Name is required"),
    body("email").isEmail().withMessage("Valid email required"),
    body("password").isLength({ min: 6 }).withMessage("Password too short"),
  ],
  authController.register
);

router.post(
  "/login",
  [
    body("email").notEmpty().withMessage("Email or username required"),
    body("password").notEmpty().withMessage("Password required"),
  ],
  authController.login
);

router.get("/me", authMiddleware, authController.me);

module.exports = router;
