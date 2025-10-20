# Use rocker image that has R pre-installed
FROM rocker/r-ver:4.3.2 AS r-stage

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install R packages with dependencies (using standard R method)
RUN R -e "install.packages(c('plumber', 'data.table', 'jsonlite'), dependencies = TRUE, repos = 'https://cran.rstudio.com/')"

# Final stage - use the R image as base
FROM r-stage

WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

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