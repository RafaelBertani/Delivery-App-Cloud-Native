#!/bin/bash
set -euo pipefail

NS=delivery-app

echo "🚀 Applying Kubernetes resources to namespace: $NS"

# 1. Namespace
echo "Creating namespace..."
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

# 2. Configurações e Segredos
echo "Applying ConfigMap and Secrets..."
kubectl apply -f ../k8s/configmap.yaml
kubectl apply -f ../k8s/secret.yaml

# 3. Infraestrutura (Bases de Dados e Mensageria)
echo "Applying Infrastructure (Postgres & RabbitMQ)..."
kubectl apply -f ../k8s/infrastructure/postgres-deployment.yaml
kubectl apply -f ../k8s/infrastructure/rabbitmq-deployment.yaml

# Pequena pausa para garantir que o Kubernetes processa a infraestrutura
echo "Waiting 10 seconds for infrastructure to initialize..."
sleep 10

# 4. Aplicações Node.js e Frontends
echo "Applying Microservices and Frontends..."
kubectl apply -f ../k8s/apps/

# 5. Ingress
echo "Applying Ingress routing..."
kubectl apply -f ../k8s/ingress.yaml

echo "✅ Resources applied. Current status:"
kubectl get all -n "$NS"
kubectl get ingress -n "$NS"
echo ""
echo "🌍 Access your apps at:"
echo "👉 React:   http://localhost:8080/"
echo "👉 Flutter: http://localhost:8081/"