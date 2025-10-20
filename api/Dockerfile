FROM python:3.11-slim

WORKDIR /app

# Install system dependencies including R
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    r-base \
    r-base-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libsodium-dev \
    libgit2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    && rm -rf /var/lib/apt/lists/*

# Install required R packages with error handling
RUN R -e "options(repos = c(CRAN = 'https://cran.rstudio.com/')); \
    install.packages(c('plumber', 'data.table', 'jsonlite'), \
    dependencies = TRUE, \
    clean = TRUE)" || exit 1

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY api/ .

# Copy R backend files
COPY r-backend/ ./r-backend/

# Make start script executable
RUN chmod +x start.sh

# Expose port 9000 for Cloud Run multi-container
EXPOSE 9000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT:-9000}/health || exit 1

# Run both Python and R servers
CMD ["./start.sh"]