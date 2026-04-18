# ============================================================
# Stage 1: Builder — cài dependencies
# ============================================================
FROM node:20-alpine AS builder

WORKDIR /build

# Copy package files trước để tận dụng cache
COPY package*.json ./

# Chỉ cài production deps
RUN npm ci --omit=dev --audit \
    && npm audit --audit-level=moderate || true

# Copy source
COPY src/ ./src/
# ⚠️ Nếu KHÔNG có thư mục public thì để comment
# COPY public/ ./public/

# ============================================================
# Stage 2: Production image
# ============================================================
FROM node:20-alpine AS production

RUN apk add --no-cache wget tini

# Tạo user không phải root
RUN addgroup -g 1001 -S appgroup \
    && adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Tạo thư mục logs
RUN mkdir -p /app/logs \
    && chown -R appuser:appgroup /app

# Copy từ builder
COPY --chown=appuser:appgroup --from=builder /build/node_modules ./node_modules
COPY --chown=appuser:appgroup --from=builder /build/src ./src
# ⚠️ Nếu KHÔNG có public thì không cần dòng này
# COPY --chown=appuser:appgroup --from=builder /build/public ./public
COPY --chown=appuser:appgroup package.json ./

# Chạy bằng user thường
USER appuser

EXPOSE 3000

ENTRYPOINT ["/sbin/tini", "--"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

CMD ["node", "src/server.js"]
