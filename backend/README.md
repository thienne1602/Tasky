# Tasky REST API

This Express API powers the Tasky Flutter application. It exposes CRUD endpoints for users, teams, tasks, and comments while using MySQL for persistence.

## Quick start

1. Copy `.env.example` to `.env` and fill in the database connection details plus a secure `JWT_SECRET`.
1. Install dependencies

```bash
npm install
```

1. Create the schema on your Laragon MySQL instance. The quickest way is

```bash
npm run db:init
```

This command reads `.env`, creates the database if it does not exist, and
runs `database/schema.sql`. You can still apply the SQL manually if you
prefer.

1. Run the server

```bash
npm run dev
```

The server listens on `http://localhost:4000` by default and exposes its routes under the `/api` prefix.

## Database schema

```sql
CREATE DATABASE IF NOT EXISTS tasky_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE tasky_db;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(160) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  avatar VARCHAR(255) NULL,
  role ENUM('owner', 'member', 'viewer') DEFAULT 'member',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE teams (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  description TEXT NULL,
  owner_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE team_members (
  team_id INT NOT NULL,
  user_id INT NOT NULL,
  role ENUM('owner', 'admin', 'member') DEFAULT 'member',
  joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (team_id, user_id),
  FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE tasks (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(200) NOT NULL,
  description TEXT,
  deadline DATETIME NULL,
  status ENUM('todo', 'doing', 'done') DEFAULT 'todo',
  assigned_to INT NULL,
  team_id INT NOT NULL,
  created_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE comments (
  id INT AUTO_INCREMENT PRIMARY KEY,
  task_id INT NOT NULL,
  user_id INT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE notifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  task_id INT NOT NULL,
  message VARCHAR(255) NOT NULL,
  is_read TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
);
```

## API surface

| Method | Path                                     | Description                              |
| ------ | ---------------------------------------- | ---------------------------------------- |
| POST   | `/api/auth/register`                     | Register a new user                      |
| POST   | `/api/auth/login`                        | Authenticate and receive JWT             |
| GET    | `/api/auth/me`                           | Fetch current user profile               |
| GET    | `/api/users`                             | List users (auth required)               |
| PUT    | `/api/users/me`                          | Update profile display data              |
| GET    | `/api/teams`                             | Teams for the logged-in user             |
| POST   | `/api/teams`                             | Create a new team                        |
| POST   | `/api/teams/:teamId/members`             | Invite/add member via email              |
| GET    | `/api/teams/:teamId`                     | Team detail including members and tasks  |
| GET    | `/api/tasks`                             | Tasks assigned to or within user's teams |
| POST   | `/api/tasks`                             | Create task                              |
| GET    | `/api/tasks/:taskId`                     | Task detail with comments                |
| PUT    | `/api/tasks/:taskId`                     | Update task                              |
| DELETE | `/api/tasks/:taskId`                     | Remove task                              |
| POST   | `/api/tasks/:taskId/comments`            | Add internal task comment                |
| DELETE | `/api/tasks/:taskId/comments/:commentId` | Delete own comment                       |

## Development notes

- Authentication uses JSON Web Tokens. Send requests with header `Authorization: Bearer <token>`.
- The API currently trusts team membership for task operations. Consider adding stricter authorization checks before production use.
- Deadline reminders are exposed via a `notifications` table to support future cron-based jobs.
