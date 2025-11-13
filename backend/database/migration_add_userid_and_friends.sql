-- Migration script: Add user_id and friendships table
-- Run this AFTER the existing schema to add new features

-- Step 1: Add user_id column to users table
ALTER TABLE users ADD COLUMN user_id VARCHAR(50) AFTER id;

-- Step 2: Generate user_id for existing users
UPDATE users 
SET user_id = CONCAT(
  LOWER(REPLACE(REGEXP_REPLACE(name, '[^a-zA-Z0-9]', ''), ' ', '')),
  FLOOR(1000 + RAND() * 9000)
)
WHERE user_id IS NULL OR user_id = '';

-- Step 3: Make user_id unique and NOT NULL
ALTER TABLE users MODIFY COLUMN user_id VARCHAR(50) NOT NULL UNIQUE;

-- Step 4: Create friendships table
CREATE TABLE IF NOT EXISTS friendships (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  friend_id INT NOT NULL,
  status ENUM('pending', 'accepted', 'blocked') DEFAULT 'accepted',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (friend_id) REFERENCES users(id) ON DELETE CASCADE,
  UNIQUE KEY unique_friendship (user_id, friend_id)
);

-- Done! Schema updated successfully.
