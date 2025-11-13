-- Migration: Add leader role support
-- Date: 2025-11-11

-- Update team_members table to support leader role
ALTER TABLE team_members 
  MODIFY COLUMN role ENUM('owner', 'leader', 'admin', 'member') DEFAULT 'member';

-- Update existing owner to leader (backward compatibility)
UPDATE team_members 
SET role = 'leader' 
WHERE role = 'owner';

-- Ensure team creator is leader
UPDATE team_members tm
INNER JOIN teams t ON tm.team_id = t.id AND tm.user_id = t.owner_id
SET tm.role = 'leader';
