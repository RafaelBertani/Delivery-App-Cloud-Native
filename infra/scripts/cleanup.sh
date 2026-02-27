#!/bin/bash
set -euo pipefail

echo "🧹 CLEANING EVERYTHING - Delivery App"
echo "============================================="

# 1. Kubernetes cleanup
echo "📦 Cleaning Kubernetes resources..."
if kubectl get namespace delivery-app >/dev/null 2>&1; then
    # O comando delete namespace apaga todos os deployments, services e pvc lá dentro!
    kubectl delete namespace delivery-app
    echo "✅ Kubernetes namespace 'delivery-app' deleted"
else
    echo "ℹ️  Kubernetes namespace not found"
fi

# 2. Stop and remove containers (Opcional se usar apenas Minikube/Docker Desktop K8s, mas útil para limpar resíduos do swarm)
echo "🐳 Cleaning Docker containers..."
if [ $(docker ps -aq | wc -l) -gt 0 ]; then
    docker stop $(docker ps -aq) 2>/dev/null || true
    docker rm $(docker ps -aq) 2>/dev/null || true
    echo "✅ Docker containers cleaned"
else
    echo "ℹ️  No Docker containers to clean"
fi

# 3. Remove project images
echo "🖼️  Cleaning Docker images..."
PROJECT_IMAGES=(
    "auth-service:latest"
    "restaurant-service:latest"
    "order-service:latest"
    "delivery-app/front-apps/web_react:latest"
    "delivery-app/front-apps/mobile_flutter:latest"
)

for image in "${PROJECT_IMAGES[@]}"; do
    if docker images -q "$image" >/dev/null 2>&1; then
        docker rmi -f "$image" 2>/dev/null || true
        echo "✅ Removed $image"
    fi
done

# 4. Clean up unused resources
echo "🧽 Cleaning unused Docker resources..."
docker volume prune -f >/dev/null 2>&1 || true
docker network prune -f >/dev/null 2>&1 || true

echo ""
echo "🎉 CLEANUP COMPLETED!"
echo "===================="
echo "To rebuild everything:"
echo "1. bash scripts/build-images.sh"
echo "2. bash scripts/deploy.sh"

# kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0/deploy/static/provider/cloud/deploy.yaml
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.0/deploy/static/provider/cloud/deploy.yaml
