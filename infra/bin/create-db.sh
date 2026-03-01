set -e

NAMESPACE="delivery-app"
DEPLOYMENT="deployment/postgres"

echo "🔍 Conectando ao Postgres no Kubernetes..."

echo "🚀 Executando script SQL..."

kubectl exec -i $DEPLOYMENT -n $NAMESPACE -- psql -U postgres < "$(dirname "$0")/../db/init.sql"

echo "🎉 Banco e tabelas criados com sucesso!"
echo "⏳ Aguardando 5 segundos..."
sleep 5
