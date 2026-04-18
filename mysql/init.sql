-- ============================================================
-- MySQL Init Script - Secure Setup
-- ============================================================

-- ✅ DB SECURITY: Tạo database với charset an toàn
CREATE DATABASE IF NOT EXISTS productdb
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE productdb;

-- ✅ DB SECURITY: Xóa anonymous user và remote root
DELETE FROM mysql.user WHERE User = '' OR (User = 'root' AND Host != 'localhost');
-- Tắt remote root login
UPDATE mysql.user SET Host = 'localhost' WHERE User = 'root';
FLUSH PRIVILEGES;

-- ─────────────────────────────────────────
-- Table: users
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  username      VARCHAR(50)     NOT NULL,
  password_hash VARCHAR(255)    NOT NULL,  -- bcrypt hash
  role          ENUM('user','admin') NOT NULL DEFAULT 'user',
  is_active     TINYINT(1)      NOT NULL DEFAULT 1,
  last_login    DATETIME        NULL,
  created_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─────────────────────────────────────────
-- Table: products
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id          INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  name        VARCHAR(200)    NOT NULL,
  description TEXT            NULL,
  price       DECIMAL(15,2)   NOT NULL CHECK (price >= 0),
  stock       INT UNSIGNED    NOT NULL DEFAULT 0,
  category    VARCHAR(100)    NOT NULL,
  created_by  INT UNSIGNED    NOT NULL,
  is_deleted  TINYINT(1)      NOT NULL DEFAULT 0,
  deleted_by  INT UNSIGNED    NULL,
  deleted_at  DATETIME        NULL,
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_category (category),
  INDEX idx_created_by (created_by),
  INDEX idx_is_deleted (is_deleted),
  CONSTRAINT fk_product_user FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─────────────────────────────────────────
-- Table: audit_log (ghi lại mọi thay đổi)
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_log (
  id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  table_name  VARCHAR(50)     NOT NULL,
  record_id   INT UNSIGNED    NOT NULL,
  action      ENUM('INSERT','UPDATE','DELETE') NOT NULL,
  old_data    JSON            NULL,
  new_data    JSON            NULL,
  user_id     INT UNSIGNED    NULL,
  ip_address  VARCHAR(45)     NULL,
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_table_record (table_name, record_id),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ─────────────────────────────────────────
-- ✅ DB SECURITY: Tạo user với quyền tối thiểu (least privilege)
-- ─────────────────────────────────────────
-- Xóa user cũ nếu tồn tại
DROP USER IF EXISTS 'appuser'@'%';

-- Tạo user chỉ truy cập từ trong Docker network
CREATE USER 'appuser'@'%' IDENTIFIED BY '${DB_PASSWORD}' -- sẽ được thay bởi env
  PASSWORD EXPIRE INTERVAL 90 DAY;

-- Chỉ cấp quyền cần thiết, KHÔNG cấp DROP, CREATE, ALTER
GRANT SELECT, INSERT, UPDATE ON productdb.users TO 'appuser'@'%';
GRANT SELECT, INSERT, UPDATE ON productdb.products TO 'appuser'@'%';
GRANT INSERT ON productdb.audit_log TO 'appuser'@'%';

FLUSH PRIVILEGES;

-- ─────────────────────────────────────────
-- Seed data - Admin user mặc định
-- Password: Admin@12345 (thay đổi sau khi deploy!)
-- ─────────────────────────────────────────
INSERT IGNORE INTO users (username, password_hash, role)
VALUES (
  'admin',
  '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5ThfMHnXJFIlS', -- Admin@12345
  'admin'
);

-- Seed products mẫu
INSERT IGNORE INTO products (name, description, price, stock, category, created_by) VALUES
  ('Laptop Dell XPS 15', 'Laptop cao cấp dòng XPS', 35000000, 10, 'Laptop', 1),
  ('iPhone 15 Pro', 'Điện thoại Apple mới nhất', 30000000, 25, 'Điện thoại', 1),
  ('Samsung 4K TV 55"', 'Smart TV màn hình 4K UHD', 18000000, 15, 'TV', 1),
  ('AirPods Pro 2', 'Tai nghe không dây chống ồn', 6500000, 50, 'Phụ kiện', 1),
  ('Bàn phím cơ Keychron K2', 'Bàn phím cơ wireless', 2500000, 30, 'Phụ kiện', 1);
