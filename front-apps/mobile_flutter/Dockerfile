# Estágio 1: Build da aplicação Flutter para Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copia os ficheiros de dependências e instala-as primeiro (cache)
COPY pubspec.* ./
RUN flutter pub get

# Copia todo o restante código do projeto
COPY . .

# Faz a compilação otimizada para a Web
RUN flutter build web --release

# Estágio 2: Servir com o Nginx
FROM nginx:1.25-alpine

# Copia os ficheiros gerados pelo Flutter no Estágio 1
COPY --from=build /app/build/web /usr/share/nginx/html

# Copia o ficheiro nginx.conf customizado
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]