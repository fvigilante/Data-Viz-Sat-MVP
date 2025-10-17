#!/bin/bash

# Deploy to Google Cloud Run - Multi-Container Setup
# This script deploys FastAPI + R Backend + Next.js to Cloud Run

set -e

# Configuration
PROJECT_ID=${GOOGLE_CLOUD_PROJECT:-"your-project-id"}
REGION=${GOOGLE_CLOUD_REGION:-"us-central1"}
SERVICE_NAME="data-viz-satellite"

echo "🚀 Deploying Data Viz Satellite to Cloud Run..."
echo "📊 Project: $PROJECT_ID"
echo "🌍 Region: $REGION"

# Build and push images
echo "🔨 Building and pushing container images..."

# Build FastAPI image
docker build -t gcr.io/$PROJECT_ID/data-viz-api:latest ./api
docker push gcr.io/$PROJECT_ID/data-viz-api:latest

# Build R Backend image
docker build -t gcr.io/$PROJECT_ID/data-viz-r:latest ./r-backend
docker push gcr.io/$PROJECT_ID/data-viz-r:latest

# Build Next.js image
docker build -t gcr.io/$PROJECT_ID/data-viz-web:latest -f Dockerfile.production .
docker push gcr.io/$PROJECT_ID/data-viz-web:latest

# Deploy using docker-compose (Cloud Run supports this)
echo "🚀 Deploying to Cloud Run..."
gcloud run services replace docker-compose.yml \
  --region=$REGION \
  --project=$PROJECT_ID

echo "✅ Deployment complete!"
echo "🌐 Your app will be available at:"
gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)"

echo ""
echo "🎯 Test your R integration:"
echo "   FastAPI: [URL]/plots/volcano-fastapi"
echo "   R Backend: [URL]/plots/volcano-r"