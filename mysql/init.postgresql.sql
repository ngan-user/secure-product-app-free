-- ============================================================
-- init.postgresql.sql — Khởi tạo DB trên Render Free (PostgreSQL)
-- Chạy 1 lần sau khi tạo database trên Render
-- ============================================================

-- ─── Table: users ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id            SERIAL          PRIMARY KEY,
  username      VARCHAR(50)     NOT NULL UNIQUE,
  password_hash VARCHAR(255)    NOT NULL,
  role          VARCHAR(10)     NOT NULL DEFAULT 'user'
                                CHECK (role IN ('user','admin')),
  is_active     SMALLINT        NOT NULL DEFAULT 1,
  last_login    TIMESTAMP       NULL,
  created_at    TIMESTAMP       NOT NULL DEFAULT NOW()
);

-- ─── Table: products ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id          SERIAL          PRIMARY KEY,
  name        VARCHAR(200)    NOT NULL,
  description TEXT            NULL,
  price       DECIMAL(15,2)   NOT NULL CHECK (price >= 0),
  stock       INTEGER         NOT NULL DEFAULT 0 CHECK (stock >= 0),
  category    VARCHAR(100)    NOT NULL,
  created_by  INTEGER         NOT NULL REFERENCES users(id),
  is_deleted  SMALLINT        NOT NULL DEFAULT 0,
  deleted_by  INTEGER         NULL,
  deleted_at  TIMESTAMP       NULL,
  created_at  TIMESTAMP       NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMP       NOT NULL DEFAULT NOW()
);

-- ─── Table: audit_log ──────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_log (
  id          BIGSERIAL       PRIMARY KEY,
  table_name  VARCHAR(50)     NOT NULL,
  record_id   INTEGER         NOT NULL,
  action      VARCHAR(10)     NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE')),
  old_data    JSONB           NULL,
  new_data    JSONB           NULL,
  user_id     INTEGER         NULL,
  ip_address  VARCHAR(45)     NULL,
  created_at  TIMESTAMP       NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_products_category   ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_created_by ON products(created_by);
CREATE INDEX IF NOT EXISTS idx_products_is_deleted ON products(is_deleted);
CREATE INDEX IF NOT EXISTS idx_audit_table_record  ON audit_log(table_name, record_id);

-- ─── Seed: Admin user ──────────────────────────────────────
-- Password: Admin@12345
INSERT INTO users (username, password_hash, role)
VALUES (
  'admin',
  '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5ThfMHnXJFIlS',
  'admin'
) ON CONFLICT (username) DO NOTHING;

-- ─── Seed: Sản phẩm mẫu ───────────────────────────────────
INSERT INTO products (name, description, price, stock, category, created_by) VALUES
  ('Laptop Dell XPS 15',   'Laptop cao cấp dòng XPS',          35000000, 10, 'Laptop',    1),
  ('iPhone 15 Pro',        'Điện thoại Apple mới nhất',        30000000, 25, 'Điện thoại',1),
  ('Samsung 4K TV 55"',    'Smart TV màn hình 4K UHD',         18000000, 15, 'TV',        1),
  ('AirPods Pro 2',        'Tai nghe không dây chống ồn',       6500000, 50, 'Phụ kiện',  1),
  ('Bàn phím cơ Keychron', 'Bàn phím cơ wireless compact',     2500000, 30, 'Phụ kiện',  1)
ON CONFLICT DO NOTHING;
