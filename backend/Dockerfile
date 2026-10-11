# Stage 1: Build & Dependencies
FROM node:20-slim AS builder

WORKDIR /app

# Install OpenSSL required by Prisma engine
RUN apt-get update -y && apt-get install -y openssl ca-certificates && rm -rf /var/lib/apt/lists/*

# Copy package files and prisma schema first for cached layer builds
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies (including devDependencies needed for build)
RUN npm ci

# Generate Prisma Client
RUN npx prisma generate

# Copy source code and config
COPY tsconfig*.json nest-cli.json ./
COPY src ./src/

# Compile TypeScript
RUN npm run build

# Prune devDependencies for production image
RUN npm prune --production

# ==============================================================
# Stage 2: Lean Production Runner for Google Cloud Run
# ==============================================================
FROM node:20-slim AS runner

WORKDIR /app

# Install runtime OpenSSL for Prisma
RUN apt-get update -y && apt-get install -y openssl ca-certificates && rm -rf /var/lib/apt/lists/*

ENV NODE_ENV=production
ENV PORT=8080

# Copy node_modules and generated Prisma client from builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json

# Use non-root node user for security
USER node

# Expose Cloud Run port
EXPOSE 8080

# Start NestJS application
CMD ["node", "dist/main.js"]
