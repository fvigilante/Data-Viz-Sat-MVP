# R Backend Dockerfile - Production Ready
FROM r-base:4.3.2

# Install system dependencies including curl for health checks
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash ruser

# Set working directory
WORKDIR /app

# Copy R files
COPY --chown=ruser:ruser . .

# Install R packages
RUN Rscript install-packages.R

# Switch to non-root user
USER ruser

# Expose port 8001 (Cloud Run compatible)
EXPOSE 8001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8001/health || exit 1

# Start R server
CMD ["Rscript", "plumber-api.R"]