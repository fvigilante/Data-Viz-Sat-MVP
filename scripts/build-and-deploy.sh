#!/bin/bash

# Build and Deploy Script for Google Cloud Run Multi-Container
# Usage: ./scripts/build-and-deploy.sh [PROJECT_ID] [REGION]

set -e

# Default values
DEFAULT_REGION="europe-west1"
REPOSITORY="data-viz-satellite"

# Parse arguments
PROJECT_ID=${1:-$GOOGLE_CLOUD_PROJECT}
REGION=${2:-$DEFAULT_REGION}

if [ -z "$PROJECT_ID" ]; then
    echo "Error: PROJECT_ID is required"
    echo "Usage: $0 <PROJECT_ID> [REGION]"
    echo "Or set GOOGLE_CLOUD_PROJECT environment variable"
    exit 1
fi

echo "🚀 Building and deploying Data Viz Satellite to Google Cloud Run"
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Repository: $REPOSITORY"
echo ""

# Configure Docker authentication
echo "🔐 Configuring Docker authentication..."
gcloud auth configure-docker $REGION-docker.pkg.dev

# Build and push frontend image
echo "🏗️  Building frontend image..."
docker build -f Dockerfile.production -t $REGION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY/frontend:latest .

echo "📤 Pushing frontend image..."
docker push $REGION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY/frontend:latest

# Build and push API image
echo "🏗️  Building API image..."
docker build -f api/Dockerfile -t $REGION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY/api:latest ./api

echo "📤 Pushing API image..."
docker push $REGION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY/api:latest

# Update service.yaml with project details
echo "📝 Updating service.yaml..."
cp service.yaml service-deploy.yaml
sed -i "s/PROJECT_ID/$PROJECT_ID/g" service-deploy.yaml
sed -i "s|gcr.io|$REGION-docker.pkg.dev|g" service-deploy.yaml

# Deploy to Cloud Run
echo "🚀 Deploying to Cloud Run..."
gcloud run services replace service-deploy.yaml \
    --region=$REGION \
    --allow-unauthenticated

# Get service URL
echo "✅ Deployment complete!"
SERVICE_URL=$(gcloud run services describe data-viz-satellite \
    --region=$REGION \
    --format="value(status.url)")

echo ""
echo "🌐 Service URL: $SERVICE_URL"
echo ""
echo "📊 You can now access your Data Viz Satellite application!"

# Clean up temporary file
rm service-deploy.yaml