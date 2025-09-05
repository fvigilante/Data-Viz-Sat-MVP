#!/bin/bash

# Quick fix script to update the API URL in your existing Cloud Run deployment
PROJECT_ID=${1:-"data-viz-satellite-mvp"}
REGION=${2:-"europe-west1"}
SERVICE_NAME=${3:-"data-viz-sat-mvp"}

echo "🔧 Fixing API URL configuration for Cloud Run service"
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Service: $SERVICE_NAME"
echo ""

# Set the project
gcloud config set project $PROJECT_ID

# Update the service with correct environment variables
echo "📝 Updating service configuration..."

# Create a temporary service.yaml with your actual project ID
sed "s/PROJECT_ID/$PROJECT_ID/g" service.yaml > service-temp.yaml

# Deploy the updated configuration
gcloud run services replace service-temp.yaml --region=$REGION --platform=managed

# Clean up
rm service-temp.yaml

# Get the service URL
echo "🌐 Getting service URL..."
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")

echo ""
echo "✅ Configuration updated!"
echo "🌍 Service URL: $SERVICE_URL"
echo ""
echo "The frontend should now correctly call the API at http://127.0.0.1:9000"
echo "Test your deployment at: $SERVICE_URL"