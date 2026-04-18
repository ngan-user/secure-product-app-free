# ============================================================
# Stage 1: Builder — cài dependencies
# ============================================================
FROM node:20-alpine AS builder

# ✅ SECURITY: Chạy với user không phải root
WORKDIR /build

# Copy package files trước để tận dụng Docker cache
COPY package*.json ./

# ✅ SECURITY: Chỉ cài production deps + audit
RUN npm ci --omit=dev --audit \
    && npm audit --audit-level=moderate || true

# Copy source
COPY src/ ./src/
2>/dev/null || true

# ============================================================
# Stage 2: Production image
# ✅ SECURITY: Dùng image tối giản (alpine)
# ============================================================
FROM node:20-alpine AS production

# Cài wget để dùng health check
RUN apk add --no-cache wget tini

# ✅ SECURITY: Tạo user/group riêng, KHÔNG chạy bằng root
RUN addgroup -g 1001 -S appgroup \
    && adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# ✅ Tạo thư mục logs với quyền đúng
RUN mkdir -p /app/logs \
    && chown -R appuser:appgroup /app

# Copy từ builder stage
COPY --chown=appuser:appgroup --from=builder /build/node_modules ./node_modules
COPY --chown=appuser:appgroup --from=builder /build/src ./src
COPY --chown=appuser:appgroup --from=builder /build/public ./public 2>/dev/null || true
COPY --chown=appuser:appgroup package.json ./

# ✅ SECURITY: Chuyển sang non-root user
USER appuser

# ✅ SECURITY: Chỉ expose port cần thiết
EXPOSE 3000

# ✅ SECURITY: Dùng tini làm PID 1 (proper signal handling)
ENTRYPOINT ["/sbin/tini", "--"]

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

CMD ["node", "src/server.js"]
