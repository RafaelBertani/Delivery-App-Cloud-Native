# # ===============================
# # CONFIGURAÇÃO DE VARIÁVEIS (cabeçalho)
# # ===============================
# JWT_SECRET="ifthispasswordwentonlineifailed"

# POSTGRES_USER="postgres"
# POSTGRES_PASSWORD="db#1post"
# POSTGRES_DB="postgres_db_delivery"

# RABBITMQ_USER="guest"
# RABBITMQ_PASSWORD="guest"

# # ===============================
# # FIM DO CABEÇALHO
# # ===============================

# # Função para criar secret (remove se já existir)
# create_secret() {
#   local secret_name=$1
#   local secret_value=$2

#   if docker secret ls | grep -w $secret_name > /dev/null; then
#     echo "Secret $secret_name já existe. Removendo..."
#     docker secret rm $secret_name
#   fi

#   echo "$secret_value" | docker secret create $secret_name -
#   echo "Secret $secret_name criado com sucesso!"
# }

# # Checa se o Swarm está ativo
# if [ "$(docker info --format '{{.Swarm.LocalNodeState}}')" != "active" ]; then
#   echo "Swarm não está ativo. Inicializando..."
#   docker swarm init
# fi

# echo "Criando secrets..."

# # Criar todos os secrets
# create_secret jwt_secret "$JWT_SECRET"

# create_secret postgres_user "$POSTGRES_USER"
# create_secret postgres_password "$POSTGRES_PASSWORD"
# create_secret postgres_db_delivery "$POSTGRES_DB"

# create_secret rabbitmq_user "$RABBITMQ_USER"
# create_secret rabbitmq_password "$RABBITMQ_PASSWORD"

# echo "Todos os secrets foram criados com sucesso!"
