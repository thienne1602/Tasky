const mysql = require("mysql2/promise");
const bcrypt = require("bcryptjs");
const fs = require("fs");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

async function hashPassword(password) {
  return await bcrypt.hash(password, 10);
}

async function seedData() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || "127.0.0.1",
    port: Number(process.env.DB_PORT ?? 3306),
    user: process.env.DB_USER || "root",
    password: process.env.DB_PASSWORD ?? "",
    database: process.env.DB_NAME || "tasky_db",
  });

  try {
    console.log("🌱 Seeding data...");

    // Clear existing data
    console.log("🧹 Clearing existing data...");
    await connection.query("SET FOREIGN_KEY_CHECKS = 0");
    await connection.query("TRUNCATE TABLE notifications");
    await connection.query("TRUNCATE TABLE comments");
    await connection.query("TRUNCATE TABLE tasks");
    await connection.query("TRUNCATE TABLE team_members");
    await connection.query("TRUNCATE TABLE teams");
    await connection.query("TRUNCATE TABLE friendships");
    await connection.query("TRUNCATE TABLE users");
    await connection.query("SET FOREIGN_KEY_CHECKS = 1");

    // Seed Users
    console.log("👥 Seeding users...");
    const users = [
      {
        user_id: "admin1",
        name: "Nguyễn Văn Minh",
        email: "minh.nguyen@example.com",
        role: "owner",
      },
      {
        user_id: "admin2",
        name: "Trần Thị Lan",
        email: "lan.tran@example.com",
        role: "owner",
      },
      {
        user_id: "dev1",
        name: "Lê Hoàng Anh",
        email: "anh.le@example.com",
        role: "member",
      },
      {
        user_id: "dev2",
        name: "Phạm Thị Mai",
        email: "mai.pham@example.com",
        role: "member",
      },
      {
        user_id: "dev3",
        name: "Hoàng Văn Tùng",
        email: "tung.hoang@example.com",
        role: "member",
      },
      {
        user_id: "dev4",
        name: "Đỗ Thị Linh",
        email: "linh.do@example.com",
        role: "member",
      },
      {
        user_id: "dev5",
        name: "Vũ Văn Hùng",
        email: "hung.vu@example.com",
        role: "member",
      },
      {
        user_id: "dev6",
        name: "Bùi Thị Hoa",
        email: "hoa.bui@example.com",
        role: "member",
      },
      {
        user_id: "dev7",
        name: "Ngô Văn Đức",
        email: "duc.ngo@example.com",
        role: "member",
      },
      {
        user_id: "dev8",
        name: "Đinh Thị Nga",
        email: "nga.dinh@example.com",
        role: "member",
      },
      // Thêm tài khoản cũ của người dùng
      {
        user_id: "thien",
        name: "Thien",
        email: "thien@example.com",
        role: "member",
      },
      {
        user_id: "beiu",
        name: "Beiu",
        email: "beiu@example.com",
        role: "member",
      },
    ];

    const defaultPassword = await hashPassword("password123");
    const oldAccountsPassword = await hashPassword("abcd0000");

    for (const user of users) {
      // Sử dụng mật khẩu khác cho tài khoản cũ
      const userPassword =
        user.user_id === "thien" || user.user_id === "beiu"
          ? oldAccountsPassword
          : defaultPassword;

      await connection.query(
        "INSERT INTO users (user_id, name, email, password_hash, role) VALUES (?, ?, ?, ?, ?)",
        [user.user_id, user.name, user.email, userPassword, user.role]
      );
    }

    console.log(`✅ Created ${users.length} users`);

    // Get user IDs
    const [userRows] = await connection.query("SELECT id, user_id FROM users");
    const userMap = {};
    userRows.forEach((user) => {
      userMap[user.user_id] = user.id;
    });

    // Seed Teams
    console.log("👥 Seeding teams...");
    const teams = [
      {
        name: "Frontend Team",
        description:
          "Nhóm phát triển giao diện người dùng với React, Flutter và Vue.js",
        owner_id: userMap.admin1,
      },
      {
        name: "Backend Team",
        description: "Nhóm phát triển backend với Node.js, Python và Java",
        owner_id: userMap.admin2,
      },
    ];

    const teamIds = [];
    for (const team of teams) {
      const [result] = await connection.query(
        "INSERT INTO teams (name, description, owner_id) VALUES (?, ?, ?)",
        [team.name, team.description, team.owner_id]
      );
      teamIds.push(result.insertId);
    }

    console.log(`✅ Created ${teams.length} teams`);

    // Seed Team Members (5 members per team)
    console.log("👥 Seeding team members...");
    const frontendTeamMembers = [
      { user_id: userMap.dev1, role: "member" },
      { user_id: userMap.dev2, role: "member" },
      { user_id: userMap.dev3, role: "member" },
      { user_id: userMap.dev4, role: "admin" }, // dev4 là admin của frontend team
      { user_id: userMap.admin1, role: "owner" }, // admin1 là owner
      { user_id: userMap.thien, role: "member" }, // Thêm tài khoản cũ
    ];

    const backendTeamMembers = [
      { user_id: userMap.dev5, role: "member" },
      { user_id: userMap.dev6, role: "member" },
      { user_id: userMap.dev7, role: "member" },
      { user_id: userMap.dev8, role: "admin" }, // dev8 là admin của backend team
      { user_id: userMap.admin2, role: "owner" }, // admin2 là owner
      { user_id: userMap.beiu, role: "member" }, // Thêm tài khoản cũ
    ];

    for (const member of frontendTeamMembers) {
      await connection.query(
        "INSERT INTO team_members (team_id, user_id, role) VALUES (?, ?, ?)",
        [teamIds[0], member.user_id, member.role]
      );
    }

    for (const member of backendTeamMembers) {
      await connection.query(
        "INSERT INTO team_members (team_id, user_id, role) VALUES (?, ?, ?)",
        [teamIds[1], member.user_id, member.role]
      );
    }

    console.log("✅ Added team members");

    // Seed Tasks (1 month ago to 1 month future)
    console.log("📋 Seeding tasks...");
    const now = new Date();
    const oneMonthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
    const oneMonthFuture = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);

    const frontendTasks = [
      {
        title: "Thiết kế giao diện đăng nhập",
        description: "Tạo mockup và prototype cho trang đăng nhập",
        status: "done",
        assigned_to: userMap.dev1,
      },
      {
        title: "Tích hợp API authentication",
        description: "Kết nối với backend API cho đăng nhập/đăng ký",
        status: "done",
        assigned_to: userMap.dev2,
      },
      {
        title: "Responsive design cho mobile",
        description: "Đảm bảo giao diện hoạt động tốt trên tất cả thiết bị",
        status: "doing",
        assigned_to: userMap.dev3,
      },
      {
        title: "Tối ưu performance loading",
        description: "Cải thiện tốc độ tải trang và trải nghiệm người dùng",
        status: "todo",
        assigned_to: userMap.dev4,
      },
      {
        title: "Unit test components",
        description: "Viết unit test cho các React components",
        status: "todo",
        assigned_to: userMap.dev1,
      },
      {
        title: "Dark mode implementation",
        description: "Thêm chế độ dark mode cho toàn bộ ứng dụng",
        status: "doing",
        assigned_to: userMap.dev2,
      },
      {
        title: "Accessibility improvements",
        description: "Cải thiện khả năng truy cập cho người khuyết tật",
        status: "todo",
        assigned_to: userMap.dev3,
      },
      {
        title: "Code review và refactor",
        description: "Review code và refactor các components cũ",
        status: "done",
        assigned_to: userMap.admin1,
      },
      {
        title: "UI/UX design system",
        description: "Tạo design system thống nhất cho toàn bộ app",
        status: "doing",
        assigned_to: userMap.dev4,
      },
      {
        title: "Integration testing",
        description: "Viết integration test cho các flow chính",
        status: "todo",
        assigned_to: userMap.dev1,
      },
      {
        title: "Error handling UI",
        description: "Cải thiện cách hiển thị lỗi cho người dùng",
        status: "done",
        assigned_to: userMap.dev2,
      },
      {
        title: "Animation và transitions",
        description: "Thêm animation mượt mà cho các tương tác",
        status: "doing",
        assigned_to: userMap.dev3,
      },
      // Thêm tasks cho tài khoản cũ
      {
        title: "Thiết kế logo mới",
        description: "Tạo logo mới cho ứng dụng với phong cách hiện đại",
        status: "done",
        assigned_to: userMap.thien,
      },
      {
        title: "Tối ưu hóa hình ảnh",
        description: "Nén và tối ưu hình ảnh để tăng tốc độ tải",
        status: "doing",
        assigned_to: userMap.thien,
      },
    ];

    const backendTasks = [
      {
        title: "Database schema design",
        description: "Thiết kế schema cho user management và tasks",
        status: "done",
        assigned_to: userMap.dev5,
      },
      {
        title: "REST API development",
        description: "Phát triển REST API cho CRUD operations",
        status: "done",
        assigned_to: userMap.dev6,
      },
      {
        title: "Authentication middleware",
        description: "Implement JWT authentication middleware",
        status: "doing",
        assigned_to: userMap.dev7,
      },
      {
        title: "Database optimization",
        description: "Tối ưu query và index cho performance",
        status: "todo",
        assigned_to: userMap.dev8,
      },
      {
        title: "Error handling system",
        description: "Implement comprehensive error handling",
        status: "todo",
        assigned_to: userMap.dev5,
      },
      {
        title: "API documentation",
        description: "Tạo Swagger documentation cho APIs",
        status: "doing",
        assigned_to: userMap.dev6,
      },
      {
        title: "Security audit",
        description: "Review và fix security vulnerabilities",
        status: "todo",
        assigned_to: userMap.dev7,
      },
      {
        title: "Caching strategy",
        description: "Implement Redis caching cho performance",
        status: "doing",
        assigned_to: userMap.dev8,
      },
      {
        title: "Logging system",
        description: "Setup centralized logging với Winston",
        status: "done",
        assigned_to: userMap.admin2,
      },
      {
        title: "Testing framework",
        description: "Setup Jest và viết API tests",
        status: "todo",
        assigned_to: userMap.dev5,
      },
      {
        title: "Docker containerization",
        description: "Containerize ứng dụng với Docker",
        status: "doing",
        assigned_to: userMap.dev6,
      },
      {
        title: "CI/CD pipeline",
        description: "Setup automated deployment pipeline",
        status: "todo",
        assigned_to: userMap.dev7,
      },
      // Thêm tasks cho tài khoản cũ
      {
        title: "API rate limiting",
        description: "Implement rate limiting để bảo vệ API khỏi abuse",
        status: "done",
        assigned_to: userMap.beiu,
      },
      {
        title: "Database backup system",
        description: "Setup automated backup cho database",
        status: "doing",
        assigned_to: userMap.beiu,
      },
    ];

    // Generate random deadlines within the past month and next month
    function getRandomDeadline() {
      const start = oneMonthAgo.getTime();
      const end = oneMonthFuture.getTime();
      const randomTime = start + Math.random() * (end - start);
      return new Date(randomTime);
    }

    // Seed Frontend Tasks
    for (let i = 0; i < frontendTasks.length; i++) {
      const task = frontendTasks[i];
      const deadline = getRandomDeadline();
      await connection.query(
        "INSERT INTO tasks (title, description, deadline, status, assigned_to, team_id, created_by) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [
          task.title,
          task.description,
          deadline,
          task.status,
          task.assigned_to,
          teamIds[0],
          userMap.admin1,
        ]
      );
    }

    // Seed Backend Tasks
    for (let i = 0; i < backendTasks.length; i++) {
      const task = backendTasks[i];
      const deadline = getRandomDeadline();
      await connection.query(
        "INSERT INTO tasks (title, description, deadline, status, assigned_to, team_id, created_by) VALUES (?, ?, ?, ?, ?, ?, ?)",
        [
          task.title,
          task.description,
          deadline,
          task.status,
          task.assigned_to,
          teamIds[1],
          userMap.admin2,
        ]
      );
    }

    console.log(
      `✅ Created ${frontendTasks.length + backendTasks.length} tasks`
    );

    // Seed Friendships (mối quan hệ bạn bè)
    console.log("🤝 Seeding friendships...");
    const friendships = [
      [userMap.admin1, userMap.admin2],
      [userMap.dev1, userMap.dev2],
      [userMap.dev3, userMap.dev4],
      [userMap.dev5, userMap.dev6],
      [userMap.dev7, userMap.dev8],
      [userMap.dev1, userMap.dev5],
      [userMap.dev2, userMap.dev6],
    ];

    for (const [userId, friendId] of friendships) {
      await connection.query(
        "INSERT INTO friendships (user_id, friend_id, status) VALUES (?, ?, 'accepted')",
        [userId, friendId]
      );
      await connection.query(
        "INSERT INTO friendships (user_id, friend_id, status) VALUES (?, ?, 'accepted')",
        [friendId, userId]
      );
    }

    console.log(`✅ Created friendships`);

    // Seed some comments
    console.log("💬 Seeding comments...");
    const [taskRows] = await connection.query(
      "SELECT id, assigned_to FROM tasks LIMIT 10"
    );

    const comments = [
      "Task này đang tiến triển tốt! 👍",
      "Cần thêm thời gian để hoàn thành.",
      "Đã gặp một số khó khăn, cần hỗ trợ.",
      "Hoàn thành trước deadline! 🎉",
      "Code review đã được approve.",
      "Testing passed successfully!",
      "Waiting for design approval.",
      "Need more clarification on requirements.",
      "Great progress on this feature!",
      "Almost done, just need final touches.",
    ];

    for (let i = 0; i < Math.min(taskRows.length, comments.length); i++) {
      const task = taskRows[i];
      await connection.query(
        "INSERT INTO comments (task_id, user_id, content) VALUES (?, ?, ?)",
        [task.id, task.assigned_to, comments[i]]
      );
    }

    console.log(`✅ Created comments`);

    console.log("🎉 Data seeding completed successfully!");
    console.log("\n📊 Summary:");
    console.log(`   👥 ${users.length} users`);
    console.log(`   👥 ${teams.length} teams`);
    console.log(`   📋 ${frontendTasks.length + backendTasks.length} tasks`);
    console.log(`   💬 ${Math.min(taskRows.length, comments.length)} comments`);
    console.log(`   🤝 ${friendships.length * 2} friendships`);

    console.log("\n🔐 Login credentials:");
    console.log(
      "   Email: minh.nguyen@example.com | Password: password123 (Frontend Team Owner)"
    );
    console.log(
      "   Email: lan.tran@example.com | Password: password123 (Backend Team Owner)"
    );
    console.log(
      "   Email: thien@example.com | Password: abcd0000 (Your old account - Frontend Team)"
    );
    console.log(
      "   Email: beiu@example.com | Password: abcd0000 (Your old account - Backend Team)"
    );
    console.log("   All other users: password123");
  } catch (error) {
    console.error("❌ Error seeding data:", error);
    throw error;
  } finally {
    await connection.end();
  }
}

seedData().catch((error) => {
  console.error("❌ Seeding failed:", error);
  process.exit(1);
});
