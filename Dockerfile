FROM node:20-alpine AS builder

WORKDIR /build

COPY package*.json ./

RUN npm ci --omit=dev

COPY src/ ./src/

RUN mkdir -p ./public
COPY public/ ./public/

FROM node:20-alpine AS production

RUN apk add --no-cache wget tini

RUN addgroup -g 1001 -S appgroup \
    && adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

RUN mkdir -p /app/logs \
    && chown -R appuser:appgroup /app

COPY --chown=appuser:appgroup --from=builder /build/node_modules ./node_modules
COPY --chown=appuser:appgroup --from=builder /build/src ./src
COPY --chown=appuser:appgroup --from=builder /build/public ./public
COPY --chown=appuser:appgroup package.json ./

USER appuser

EXPOSE 3000

ENTRYPOINT ["/sbin/tini", "--"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1

CMD ["node", "src/server.js"]
