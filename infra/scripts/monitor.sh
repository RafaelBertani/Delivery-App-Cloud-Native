#!/bin/bash
set -euo pipefail

NS=delivery-app

echo "=========================================="
echo "🔍 DELIVERY APP - HEALTH CHECK"
echo "=========================================="

# Check if namespace exists
echo "📋 Checking namespace..."
if kubectl get namespace "$NS" >/dev/null 2>&1; then
    echo "✅ Namespace '$NS' exists"
else
    echo "❌ Namespace '$NS' not found"
    exit 1
fi

echo ""
echo "🚀 POD STATUS:"
echo "----------------------------------------"
kubectl get pods -n "$NS" --no-headers | while read line; do
    pod_name=$(echo "$line" | awk '{print $1}')
    ready=$(echo "$line" | awk '{print $2}')
    status=$(echo "$line" | awk '{print $3}')
    restarts=$(echo "$line" | awk '{print $4}')
    
    if [[ "$status" == "Running" && "$ready" == "1/1" ]]; then
        echo "✅ $pod_name: $status (Ready: $ready, Restarts: $restarts)"
    else
        echo "❌ $pod_name: $status (Ready: $ready, Restarts: $restarts)"
    fi
done

echo ""
echo "🌐 SERVICES:"
echo "----------------------------------------"
kubectl get services -n "$NS" --no-headers | while read line; do
    svc_name=$(echo "$line" | awk '{print $1}')
    svc_type=$(echo "$line" | awk '{print $2}')
    cluster_ip=$(echo "$line" | awk '{print $3}')
    
    if [[ "$cluster_ip" != "<none>" ]]; then
        echo "✅ $svc_name: $svc_type ($cluster_ip)"
    else
        echo "❌ $svc_name: $svc_type - No IP assigned"
    fi
done

echo ""
echo "🔗 INGRESS (DOMAINS):"
echo "----------------------------------------"
if kubectl get ingress -n "$NS" >/dev/null 2>&1; then
    kubectl get ingress -n "$NS" --no-headers | while read line; do
        ingress_name=$(echo "$line" | awk '{print $1}')
        hosts=$(echo "$line" | awk '{print $2}')
        address=$(echo "$line" | awk '{print $3}')
        
        if [[ "$address" != "" && "$address" != "<none>" ]]; then
            echo "✅ $ingress_name: $hosts (Address: $address)"
        else
            echo "⚠️  $ingress_name: $hosts (Pending Address... wait a minute)"
        fi
    done
else
    echo "❌ No ingress found"
fi

echo ""
echo "🌍 APPLICATION ACCESS:"
echo "----------------------------------------"
echo "👉 React Web: http://delivery-app.local"
echo "👉 Flutter:   http://flutter.delivery-app.local"
echo "👉 RabbitMQ UI: Run 'kubectl port-forward svc/rabbitmq 15672:15672 -n delivery-app' and access http://localhost:15672"

echo ""
echo "=========================================="
echo "📋 SUMMARY:"
echo "=========================================="

total_pods=$(kubectl get pods -n "$NS" --no-headers | wc -l)
running_pods=$(kubectl get pods -n "$NS" --no-headers | grep "Running" | grep "1/1" | wc -l)

echo "Pods: $running_pods/$total_pods fully operational"
echo "Services: $(kubectl get services -n "$NS" --no-headers | wc -l) configured"

if [[ "$running_pods" -eq "$total_pods" && "$total_pods" -gt 0 ]]; then
    echo "🎉 All systems operational!"
else
    echo "⚠️  Some issues detected or pods are still starting."
    echo "   Check detailed logs with: kubectl logs <pod-name> -n $NS"
fi
echo "=========================================="