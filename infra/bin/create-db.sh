# set -e

# STACK_NAME="delivery_app"
# SERVICE_NAME="postgres"

# echo "🔍 Procurando container do Postgres..."

# POSTGRES_CONTAINER=$(docker ps \
#   --filter "name=${STACK_NAME}_${SERVICE_NAME}" \
#   --format "{{.Names}}" \
#   | head -n 1)

# if [ -z "$POSTGRES_CONTAINER" ]; then
#   echo "❌ Container do Postgres não encontrado"
#   exit 1
# fi

# echo "✅ Container encontrado: $POSTGRES_CONTAINER"
# echo "🚀 Executando script SQL..."

# docker exec -i "$POSTGRES_CONTAINER" \
#   psql -U postgres < "$(dirname "$0")/../db/init.sql"

# echo "🎉 Banco e tabelas criados com sucesso"

# echo "⏳ Aguardando 10 segundos..."
# sleep 10

set -e

NAMESPACE="delivery-app"
DEPLOYMENT="deployment/postgres"

echo "🔍 Conectando ao Postgres no Kubernetes..."

# No K8s, não precisa caçar o ID do container, o kubectl exec faz isso
echo "🚀 Executando script SQL..."

kubectl exec -i $DEPLOYMENT -n $NAMESPACE -- psql -U postgres < "$(dirname "$0")/../db/init.sql"

echo "🎉 Banco e tabelas criados com sucesso!"
echo "⏳ Aguardando 5 segundos para estabilizar..."
sleep 5


