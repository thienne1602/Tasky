const fs = require("fs");
const path = require("path");
const mysql = require("mysql2/promise");
const dotenv = require("dotenv");

// Load environment variables from the backend folder
const envPath = path.resolve(__dirname, "../.env");
dotenv.config({ path: fs.existsSync(envPath) ? envPath : undefined });

async function main() {
  const schemaPath = path.resolve(__dirname, "../database/schema.sql");
  const schemaSQL = fs.readFileSync(schemaPath, "utf8");

  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || "127.0.0.1",
    port: Number(process.env.DB_PORT ?? 3306),
    user: process.env.DB_USER || "root",
    password: process.env.DB_PASSWORD ?? "",
    multipleStatements: true,
  });

  const databaseName = process.env.DB_NAME || "tasky_db";
  await connection.query(
    `CREATE DATABASE IF NOT EXISTS \`${databaseName}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`
  );
  await connection.changeUser({ database: databaseName });
  await connection.query(schemaSQL);

  console.log(`✅ Database '${databaseName}' is ready.`);
  await connection.end();
}

main().catch((error) => {
  console.error("❌ Failed to initialize database", error);
  process.exit(1);
});
