# Multi-stage Dockerfile for single Cloud Run container
# Combines Next.js frontend + FastAPI backend + R integration

# Stage 1: Build Next.js frontend
FROM node:18-alpine AS frontend-builder
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy package files and install dependencies
COPY package.json package-lock.json* ./
RUN npm ci --legacy-peer-deps && npm cache clean --force

# Copy source and build
COPY . .
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# Stage 2: Production runtime with Node.js + Python + R + Supervisor
FROM rocker/r-ver:4.3.2 AS production

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Node.js
    curl \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    # Python
    python3 \
    python3-pip \
    python3-dev \
    # Supervisor
    supervisor \
    # Build tools
    gcc \
    g++ \
    make \
    # R package dependencies
    libsodium-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libjpeg-dev \
    pkg-config \
    zlib1g-dev \
    libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "options(repos = c(CRAN = 'https://packagemanager.rstudio.com/all/__linux__/jammy/latest')); \
    install.packages('stringi', force = TRUE, dependencies = TRUE); \
    install.packages(c('data.table', 'jsonlite'), \
    dependencies = TRUE, \
    Ncpus = parallel::detectCores())"

WORKDIR /app

# Install Python dependencies
COPY api/requirements.txt ./api/
RUN pip3 install --no-cache-dir -r api/requirements.txt

# Copy API files
COPY api/ ./api/

# Copy built Next.js from frontend-builder
COPY --from=frontend-builder /app/.next/standalone ./
COPY --from=frontend-builder /app/.next/static ./.next/static
COPY --from=frontend-builder /app/public ./public

# Create supervisor configuration
RUN mkdir -p /etc/supervisor/conf.d
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create healthcheck script
COPY healthcheck.js ./

# Set environment variables
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=8080
ENV HOSTNAME="0.0.0.0"
ENV API_INTERNAL_URL="http://127.0.0.1:8001"
ENV MONITOR_ENABLED=false

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD node healthcheck.js

# Start supervisor
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]