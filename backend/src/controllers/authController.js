const bcrypt = require("bcryptjs");
const { validationResult } = require("express-validator");
const pool = require("../config/db");
const { signToken } = require("../utils/token");

// Helper to shape payload consistently
function buildUserPayload(user) {
  return {
    id: user.id,
    userId: user.user_id,
    name: user.name,
    email: user.email,
    avatar: user.avatar,
    role: user.role,
  };
}

// Helper to generate unique user_id
function generateUserId(name) {
  const cleanName = name.toLowerCase().replace(/[^a-z0-9]/g, "");
  const randomSuffix = Math.floor(1000 + Math.random() * 9000);
  return `${cleanName}${randomSuffix}`;
}

exports.register = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ success: false, errors: errors.array() });
    }

    const { name, email, password, username } = req.body;

    // Check if email already exists
    const [existing] = await pool.query(
      "SELECT id FROM users WHERE email = ?",
      [email]
    );
    if (existing.length > 0) {
      return res
        .status(409)
        .json({ success: false, message: "Email already registered" });
    }

    // Use provided username or generate one
    let userId = username
      ? username.toLowerCase().trim()
      : generateUserId(name);

    // Check if username already exists
    const [userExists] = await pool.query(
      "SELECT id FROM users WHERE user_id = ?",
      [userId]
    );
    if (userExists.length > 0) {
      return res
        .status(409)
        .json({ success: false, message: "Username already taken" });
    }

    const hash = await bcrypt.hash(password, 10);
    const [result] = await pool.query(
      "INSERT INTO users (user_id, name, email, password_hash, avatar, role) VALUES (?, ?, ?, ?, ?, ?)",
      [userId, name, email, hash, null, "member"]
    );

    const user = {
      id: result.insertId,
      user_id: userId,
      name,
      email,
      avatar: null,
      role: "member",
    };
    const token = signToken({
      id: user.id,
      email: user.email,
      role: user.role,
    });
    res.status(201).json({ success: true, data: user, token });
  } catch (error) {
    next(error);
  }
};

exports.login = async (req, res, next) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(422).json({ success: false, errors: errors.array() });
    }

    const { email, password } = req.body;

    // Try to find user by email OR username (user_id)
    const [rows] = await pool.query(
      "SELECT * FROM users WHERE email = ? OR user_id = ?",
      [email, email]
    );

    if (rows.length === 0) {
      return res
        .status(401)
        .json({ success: false, message: "Invalid credentials" });
    }

    const user = rows[0];
    const match = await bcrypt.compare(password, user.password_hash || "");
    if (!match) {
      return res
        .status(401)
        .json({ success: false, message: "Invalid credentials" });
    }

    const payload = buildUserPayload(user);
    const token = signToken({
      id: user.id,
      email: user.email,
      role: user.role,
    });
    res.json({ success: true, data: payload, token });
  } catch (error) {
    next(error);
  }
};

exports.me = async (req, res, next) => {
  try {
    const [rows] = await pool.query(
      "SELECT id, name, email, avatar, role FROM users WHERE id = ?",
      [req.user.id]
    );
    if (rows.length === 0) {
      return res
        .status(404)
        .json({ success: false, message: "User not found" });
    }
    res.json({ success: true, data: rows[0] });
  } catch (error) {
    next(error);
  }
};
