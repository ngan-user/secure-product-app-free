# 🔐 Secure Product Management App
### Đồ án: An Toàn Điện Toán Đám Mây

> **Miễn phí hoàn toàn** — Docker local + Render.com Free Tier

---

## 💰 Chi phí = $0

| Dịch vụ | Plan | Chi phí |
|---------|------|---------|
| Render Web Service | **free** | $0 |
| Render PostgreSQL | **free** | $0 (90 ngày) |
| GitHub | free | $0 |
| Docker local | free | $0 |

---

## 📁 Cấu trúc dự án

```
secure-product-app/
├── src/
│   ├── server.js                  # Entry point
│   ├── app.js                     # Express + bảo mật
│   ├── config/database.js         # MySQL (local) / PostgreSQL (Render)
│   ├── routes/auth.js             # Login / Register
│   ├── routes/products.js         # CRUD sản phẩm
│   ├── routes/health.js           # Health check
│   ├── middleware/auth.js         # JWT verification
│   ├── middleware/validate.js     # Input validation
│   ├── middleware/errorHandler.js # Error handler
│   └── utils/logger.js            # Winston logger
├── public/index.html              # Frontend SPA
├── mysql/
│   ├── init.sql                   # MySQL init (local)
│   ├── init.postgresql.sql        # PostgreSQL init (Render)
│   └── my.cnf                     # MySQL hardening
├── nginx/nginx.conf               # Reverse proxy + SSL
├── monitoring/prometheus/         # Prometheus + Alerts
├── .github/workflows/ci-cd.yml   # GitHub Actions CI/CD
├── scripts/setup.sh               # Setup Ubuntu tự động
├── Dockerfile                     # Multi-stage, non-root
├── docker-compose.yml             # Local full stack
├── render.yaml                    # ✅ Render FREE config
├── .env.example                   # Template (không có secret)
└── .gitignore                     # Bảo vệ .env, SSL, logs
```

---

## 🚀 Chạy LOCAL — Ubuntu VirtualBox

### Bước 1: Giải nén
```bash
cd ~/Downloads
unzip secure-product-app.zip
cd secure-product-app
```

### Bước 2: Chạy setup
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### Bước 3: Mở trình duyệt
| | URL |
|--|--|
| 🌐 Web App | http://localhost |
| 🔒 HTTPS | https://localhost |
| 📊 Grafana | http://localhost/grafana |

**Đăng nhập:** `admin` / `Admin@12345`

---

## ☁️ Deploy lên Render.com FREE

### Bước 1: Tạo tài khoản GitHub
Vào https://github.com → Sign up (miễn phí)

### Bước 2: Push code lên GitHub
```bash
git init
git add .
git commit -m "feat: secure product app"
git branch -M main
git remote add origin https://github.com/TEN_BAN/secure-product-app.git
git push -u origin main
```

### Bước 3: Tạo tài khoản Render
Vào https://render.com → **Sign up with GitHub** (miễn phí)

### Bước 4: Deploy từ render.yaml
1. Render Dashboard → **New → Blueprint**
2. Connect GitHub repo
3. Render tự đọc `render.yaml` và tạo:
   - ✅ Web Service (plan: free)
   - ✅ PostgreSQL Database (plan: free)

### Bước 5: Khởi tạo Database
Sau khi deploy xong, vào Render Dashboard:
1. Click vào **PostgreSQL service**
2. Copy **External Database URL**
3. Chạy file SQL khởi tạo:
```bash
psql "postgresql://..." -f mysql/init.postgresql.sql
```
Hoặc dùng tab **Query** trên Render Dashboard, paste nội dung file `mysql/init.postgresql.sql`

### Bước 6: Lấy URL public
```
https://secure-product-app.onrender.com
```

---

## ⚠️ Giới hạn Free Tier Render

| Hạn chế | Giải thích |
|---------|-----------|
| 😴 App ngủ sau 15p | Lần đầu vào sẽ chờ ~30 giây để wake up |
| 🗄️ DB free 90 ngày | Đủ để demo + bảo vệ đồ án |
| 💾 RAM 512MB | Đủ cho app Node.js nhỏ |
| 🔄 750h/tháng | Đủ dùng cả tháng |

---

## 🛡️ 5 Lớp Bảo Mật

### 1️⃣ Secure Docker Configuration
- ✅ Non-root user `appuser:1001`
- ✅ Multi-stage build `node:20-alpine`
- ✅ `read_only: true` filesystem
- ✅ `cap_drop: ALL`
- ✅ `no-new-privileges: true`
- ✅ Giới hạn CPU/RAM
- ✅ Network isolation (internal network)

### 2️⃣ Environment Variable Protection
- ✅ Không hard-code secret
- ✅ `.env` trong `.gitignore`
- ✅ `generateValue: true` — Render tự tạo JWT_SECRET
- ✅ GitHub Secrets cho CI/CD
- ✅ Logger redact password/token

### 3️⃣ Database Security
- ✅ Parameterized queries (chống SQL Injection)
- ✅ `multipleStatements: false`
- ✅ Input validation + escape
- ✅ Least privilege user
- ✅ SSL kết nối DB trên production
- ✅ Soft delete (không xóa vĩnh viễn)

### 4️⃣ CI/CD Bảo mật
- ✅ `permissions: contents: read`
- ✅ `npm audit --audit-level=high`
- ✅ Trivy Docker image scanning
- ✅ GitHub Secrets
- ✅ Deploy chỉ khi merge vào `main`

### 5️⃣ Logging & Monitoring
- ✅ Winston logger (app.log + error.log)
- ✅ Morgan HTTP logging
- ✅ Prometheus metrics
- ✅ Grafana dashboard
- ✅ 7 Alert rules
- ✅ Health check endpoint

---

## 📡 API Endpoints

```
POST /api/auth/login       Đăng nhập → JWT token
POST /api/auth/register    Đăng ký

GET    /api/products       Danh sách (phân trang + tìm kiếm)
GET    /api/products/:id   Chi tiết
POST   /api/products       Tạo mới   [JWT]
PUT    /api/products/:id   Cập nhật  [JWT]
DELETE /api/products/:id   Xóa mềm   [JWT]

GET /api/health            Health check
GET /api/health/detailed   CPU + RAM + DB status
```

---

## 🔧 Lệnh Docker hữu ích

```bash
docker compose logs -f app     # Xem logs realtime
docker compose ps              # Xem status
docker compose down            # Dừng app
docker compose down -v         # Dừng + xóa data
docker compose build --no-cache app  # Rebuild
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Node.js 20 + Express 4 |
| DB Local | MySQL 8.0 |
| DB Cloud | PostgreSQL (Render Free) |
| Auth | JWT + bcryptjs |
| Security | helmet + express-validator |
| Rate Limit | express-rate-limit |
| Logging | winston + morgan |
| Proxy | Nginx + SSL/TLS |
| Container | Docker + Compose |
| CI/CD | GitHub Actions + Trivy |
| Monitoring | Prometheus + Grafana |
| ☁️ Cloud | **Render.com (FREE)** |
# secure-product-app-free
