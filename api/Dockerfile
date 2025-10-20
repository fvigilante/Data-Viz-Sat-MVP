# Multi-stage build for production optimization
FROM rocker/r-ver:4.3.2 AS r-builder

# Install ALL system dependencies needed for R packages
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    gcc \
    g++ \
    make \
    curl \
    wget \
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
    libicu70 \
    && rm -rf /var/lib/apt/lists/*

# Install R packages with full dependencies to ensure everything works
RUN R -e "options(repos = c(CRAN = 'https://packagemanager.rstudio.com/all/__linux__/jammy/latest')); \
    install.packages('stringi', force = TRUE, dependencies = TRUE); \
    install.packages(c('plumber', 'data.table', 'jsonlite'), \
    dependencies = TRUE, \
    Ncpus = parallel::detectCores())"

# Verify R packages work
RUN R -e "library(plumber); library(data.table); library(jsonlite); cat('R packages OK\n')"

# Production stage - copy only what's needed
FROM rocker/r-ver:4.3.2 AS production

# Install minimal runtime dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    curl \
    libsodium23 \
    libcurl4 \
    libssl3 \
    libicu70 \
    && rm -rf /var/lib/apt/lists/*

# Copy R packages from builder
COPY --from=r-builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library

WORKDIR /app

# Copy and install Python dependencies
COPY api/requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy application files
COPY api/ .
COPY r-backend/ ./r-backend/

# Convert line endings and make scripts executable
RUN sed -i 's/\r$//' start.sh && \
    chmod +x start.sh && \
    sed -i 's/\r$//' r-backend/plumber-api-fixed.R && \
    chmod +x r-backend/plumber-api-fixed.R

# Verify everything works
RUN python3 -c "import fastapi, uvicorn; print('Python packages OK')" && \
    R -e "library(plumber); library(data.table); library(jsonlite); cat('R packages OK\n')"

# Expose port 9000 for Cloud Run multi-container
EXPOSE 9000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT:-9000}/health || exit 1

# Run both Python and R servers
CMD ["./start.sh"]