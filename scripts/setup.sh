#!/bin/bash
# ============================================================
# setup.sh — Script cài đặt dự án trên Ubuntu
# ============================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo -e "${BLUE}"
echo "=============================================="
echo "   Secure Product App — Setup Script"
echo "   An Toàn Điện Toán Đám Mây — Đồ Án"
echo "=============================================="
echo -e "${NC}"

# ─── Kiểm tra OS ────────────────────────────────────────────
if [[ "$(uname -s)" != "Linux" ]]; then
  error "Script này chỉ chạy trên Linux/Ubuntu"
fi

# ─── Cài Docker ─────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  info "Cài đặt Docker..."
  sudo apt-get update -qq
  sudo apt-get install -y ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  sudo usermod -aG docker "$USER"
  success "Docker đã được cài đặt"
else
  success "Docker đã có sẵn: $(docker --version)"
fi

# ─── Cài Docker Compose ─────────────────────────────────────
if ! command -v docker-compose &>/dev/null && ! docker compose version &>/dev/null 2>&1; then
  info "Cài đặt Docker Compose..."
  sudo apt-get install -y docker-compose-plugin
  success "Docker Compose đã được cài đặt"
else
  success "Docker Compose đã có sẵn"
fi

# ─── Tạo file .env ──────────────────────────────────────────
if [ ! -f .env ]; then
  info "Tạo file .env từ .env.example..."
  cp .env.example .env

  # Tự động generate các secret ngẫu nhiên
  JWT_SECRET=$(openssl rand -base64 64 | tr -d '\n')
  DB_PASSWORD=$(openssl rand -base64 24 | tr -d '\n/+=' | head -c 24)
  MYSQL_ROOT_PASSWORD=$(openssl rand -base64 24 | tr -d '\n/+=' | head -c 24)
  GRAFANA_PASSWORD=$(openssl rand -base64 16 | tr -d '\n/+=' | head -c 16)

  sed -i "s|CHANGE_ME_GENERATE_WITH_OPENSSL_RAND_BASE64_64|${JWT_SECRET}|g" .env
  sed -i "s|CHANGE_ME_STRONG_PASSWORD_HERE|${DB_PASSWORD}|g" .env
  sed -i "s|CHANGE_ME_ROOT_PASSWORD_HERE|${MYSQL_ROOT_PASSWORD}|g" .env
  sed -i "s|CHANGE_ME_GRAFANA_PASSWORD|${GRAFANA_PASSWORD}|g" .env

  success ".env đã được tạo với secrets ngẫu nhiên"
  warn "⚠️  Xem lại file .env trước khi deploy production!"
else
  warn ".env đã tồn tại — bỏ qua bước tạo"
fi

# ─── Tạo SSL self-signed cert (cho dev) ─────────────────────
if [ ! -f nginx/ssl/cert.pem ]; then
  info "Tạo SSL certificate tự ký (self-signed) cho development..."
  mkdir -p nginx/ssl
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout nginx/ssl/key.pem \
    -out nginx/ssl/cert.pem \
    -subj "/C=VN/ST=DaNang/L=DaNang/O=SecureApp/CN=localhost" 2>/dev/null \
    
  success "SSL certificate đã được tạo tại nginx/ssl/"
fi

# ─── Tạo thư mục logs ───────────────────────────────────────
mkdir -p logs
success "Thư mục logs đã sẵn sàng"

# ─── Build & Start ──────────────────────────────────────────
info "Build và khởi động containers..."
docker compose up -d --build

# ─── Chờ MySQL sẵn sàng ─────────────────────────────────────
info "Chờ MySQL khởi động..."
until docker compose exec -T mysql mysqladmin ping -h localhost --silent 2>/dev/null; do
  printf '.'
  sleep 2
done
echo ""
success "MySQL đã sẵn sàng"

# ─── Kiểm tra health ────────────────────────────────────────
sleep 5
HTTP_STATUS=$(curl -sk -o /dev/null -w "%{http_code}" http://localhost/api/health)
if [ "$HTTP_STATUS" = "200" ]; then
  success "App đang chạy và healthy!"
else
  warn "Health check trả về status: ${HTTP_STATUS} — kiểm tra logs"
fi

echo ""
echo -e "${GREEN}=============================================="
echo "   ✅ Setup hoàn tất!"
echo "=============================================="
echo -e "${NC}"
echo -e "🌐 Web App:    ${BLUE}http://localhost${NC}"
echo -e "🔒 HTTPS:      ${BLUE}https://localhost${NC}"
echo -e "📊 Grafana:    ${BLUE}http://localhost/grafana${NC}"
echo -e "   Tài khoản:  admin / $(grep GRAFANA_PASSWORD .env | cut -d= -f2)"
echo ""
echo -e "📋 Xem logs:   ${YELLOW}docker compose logs -f app${NC}"
echo -e "🛑 Dừng app:   ${YELLOW}docker compose down${NC}"
echo ""
echo -e "${RED}⚠️  Tài khoản Admin mặc định:${NC}"
echo -e "   Username: admin | Password: Admin@12345"
echo -e "${RED}   → Đổi mật khẩu ngay sau khi đăng nhập!${NC}"
