const express = require("express");
const authRoutes = require("./authRoutes");
const userRoutes = require("./userRoutes");
const teamRoutes = require("./teamRoutes");
const taskRoutes = require("./taskRoutes");
const notificationRoutes = require("./notificationRoutes");

const router = express.Router();

router.use("/auth", authRoutes);
router.use("/users", userRoutes);
router.use("/teams", teamRoutes);
router.use("/tasks", taskRoutes);
router.use("/notifications", notificationRoutes);

module.exports = router;
