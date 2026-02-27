#!/bin/bash
set -euo pipefail

echo "Building Docker images for Delivery App..."

# Build Auth Service
echo "Building auth-service..."
docker build -t auth-service:latest ../../backend/auth-service/

# Build Restaurant Service
echo "Building restaurant-service..."
docker build -t restaurant-service:latest ../../backend/restaurant-service/

# Build Order Service
echo "Building order-service..."
docker build -t order-service:latest ../../backend/order-service/

# Build Frontend React (Web)
echo "Building React frontend..."
docker build -t delivery-app/web_react:latest ../../front-apps/web_react/

# Build Frontend Flutter (Mobile/Web)
echo "Building Flutter frontend..."
docker build -t delivery-app/mobile_flutter:latest ../../front-apps/mobile_flutter/

echo "✅ All 5 custom images built successfully!"