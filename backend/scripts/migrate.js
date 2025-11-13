const mysql = require("mysql2/promise");
require("dotenv").config();

const config = {
  host: process.env.DB_HOST || "127.0.0.1",
  port: process.env.DB_PORT || 3306,
  user: process.env.DB_USER || "root",
  password: process.env.DB_PASSWORD || "",
  database: process.env.DB_NAME || "tasky_db",
  multipleStatements: true,
};

async function runMigration() {
  let connection;

  try {
    console.log("🔄 Connecting to database...");
    connection = await mysql.createConnection(config);

    console.log("✅ Connected!");
    console.log("");
    console.log("📝 Running migration: Add user_id and friendships table");
    console.log("");

    // Step 1: Check if user_id column exists
    const [columns] = await connection.query(
      "SHOW COLUMNS FROM users LIKE 'user_id'"
    );

    if (columns.length === 0) {
      console.log("[1/4] Adding user_id column...");
      await connection.query(
        "ALTER TABLE users ADD COLUMN user_id VARCHAR(50) AFTER id"
      );
      console.log("✅ user_id column added");
    } else {
      console.log("[1/4] ✅ user_id column already exists");
    }

    // Step 2: Generate user_id for existing users
    console.log("[2/4] Generating user_id for existing users...");
    const [users] = await connection.query(
      'SELECT id, name FROM users WHERE user_id IS NULL OR user_id = ""'
    );

    for (const user of users) {
      const cleanName = user.name.toLowerCase().replace(/[^a-z0-9]/g, "");
      let userId = `${cleanName}${Math.floor(1000 + Math.random() * 9000)}`;

      // Check if userId exists, regenerate if needed
      let attempts = 0;
      while (attempts < 10) {
        const [exists] = await connection.query(
          "SELECT id FROM users WHERE user_id = ?",
          [userId]
        );
        if (exists.length === 0) break;
        userId = `${cleanName}${Math.floor(1000 + Math.random() * 9000)}`;
        attempts++;
      }

      await connection.query("UPDATE users SET user_id = ? WHERE id = ?", [
        userId,
        user.id,
      ]);
      console.log(`   Generated @${userId} for ${user.name}`);
    }

    if (users.length === 0) {
      console.log("   No users need user_id generation");
    }

    // Step 3: Make user_id unique if not already
    const [indexes] = await connection.query(
      "SHOW INDEXES FROM users WHERE Key_name = 'user_id'"
    );

    if (indexes.length === 0) {
      console.log("[3/4] Making user_id unique...");
      await connection.query(
        "ALTER TABLE users MODIFY COLUMN user_id VARCHAR(50) NOT NULL"
      );
      await connection.query("ALTER TABLE users ADD UNIQUE KEY (user_id)");
      console.log("✅ user_id is now unique");
    } else {
      console.log("[3/4] ✅ user_id is already unique");
    }

    // Step 4: Create friendships table if not exists
    console.log("[4/4] Creating friendships table...");
    await connection.query(`
      CREATE TABLE IF NOT EXISTS friendships (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        friend_id INT NOT NULL,
        status ENUM('pending', 'accepted', 'blocked') DEFAULT 'accepted',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (friend_id) REFERENCES users(id) ON DELETE CASCADE,
        UNIQUE KEY unique_friendship (user_id, friend_id)
      )
    `);
    console.log("✅ friendships table ready");

    console.log("");
    console.log("════════════════════════════════════════════════════════");
    console.log("   ✅ MIGRATION COMPLETED SUCCESSFULLY!");
    console.log("════════════════════════════════════════════════════════");
    console.log("");

    // Show summary
    const [userCount] = await connection.query(
      "SELECT COUNT(*) as count FROM users"
    );
    const [friendCount] = await connection.query(
      "SELECT COUNT(*) as count FROM friendships"
    );

    console.log("📊 Summary:");
    console.log(`   Total users: ${userCount[0].count}`);
    console.log(`   Total friendships: ${friendCount[0].count}`);
    console.log("");
  } catch (error) {
    console.error("");
    console.error("❌ Migration failed!");
    console.error("Error:", error.message);
    console.error("");
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

runMigration();
