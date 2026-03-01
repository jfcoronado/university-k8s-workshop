# ── Stage 1: deps (separate layer so it caches well) ─────────────────────────
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json ./
# No external dependencies — stdlib only. If you add npm packages, uncomment:
# RUN npm ci --only=production

# ── Stage 2: final image ──────────────────────────────────────────────────────
FROM node:20-alpine
WORKDIR /app

# Create a non-root user (security best practice)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy app source
COPY server.js package.json ./

# Use the non-root user
USER appuser

EXPOSE 3000

ENV PORT=3000 \
    NODE_ENV=production \
    APP_VERSION=1.0.0 \
    APP_ENV=production \
    LOG_LEVEL=info \
    FEATURE_NEW_UI=false

HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
