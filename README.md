# Delivery-App-Cloud-Native

C:\Users\Rafael\Desktop\Delivery-App-Cloud-Native\infra> docker stack deploy -c docker-compose.yml delivery_app


docker build -t auth-service:latest ../backend/auth-service

docker stack deploy -c docker-compose.yml delivery_app
docker stack rm delivery_app

docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management

docker exec -it delivery_app psql -U postgres
docker exec -it delivery_app psql -U postgres -c "CREATE DATABASE postgres_db_delivery;"
\c postgres_db_delivery
CREATE TABLE users ( id SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL, email VARCHAR(100) UNIQUE NOT NULL, password VARCHAR(255) NOT NULL, profile_pic BYTEA, joined_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP, role VARCHAR(10) CHECK (role IN ('ADM', 'USER')) );
CREATE TABLE user_pic ( id SERIAL PRIMARY KEY, user_id INT NOT NULL REFERENCES users (id) ON DELETE CASCADE, image_data BYTEA NOT NULL, image_name VARCHAR(255), uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP );

docker exec -it delivery_app psql -U postgres
docker exec -it delivery_app psql -U postgres -c "CREATE DATABASE postgres_db_delivery;"
\c postgres_db_delivery
CREATE TABLE users ( id SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL, email VARCHAR(100) UNIQUE NOT NULL, password VARCHAR(255) NOT NULL, profile_pic BYTEA, joined_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP, phone VARCHAR(20) NOT NULL, role VARCHAR(10) CHECK (role IN ('ADM', 'USER')), is_account_active BOOLEAN DEFAULT TRUE );
CREATE TABLE addresses (  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id), street VARCHAR(255) NOT NULL, city VARCHAR(100) NOT NULL, state VARCHAR(50) NOT NULL, zip_code VARCHAR(20) NOT NULL, country VARCHAR(50) DEFAULT 'Brasil', is_active BOOLEAN DEFAULT FALSE );
CREATE TABLE orders (  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id), total_amount DECIMAL(10,2), status VARCHAR(20) CHECK (status IN ('PENDING','PREPARING','DELIVERING','DELIVERED','CANCELLED')), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, updated_at TIMESTAMP );
CREATE TABLE payment_cards (  id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id) ON DELETE CASCADE, cardholder_name VARCHAR(100) NOT NULL, card_number CHAR(16) NOT NULL, expiration_month CHAR(2) NOT NULL,  expiration_year CHAR(4) NOT NULL, card_brand VARCHAR(20), is_default BOOLEAN DEFAULT FALSE, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP );

docker exec -i delivery_app_postgres.1.i1tply90qntp86qat7gllhufy \
psql -U postgres < infra/db/init.sql

docker exec -it delivery_app_postgres.1.i1tply90qntp86qat7gllhufy psql -U postgres

cd .\bin\                                                  
PS C:\Users\Rafael\Desktop\Delivery-App-Cloud-Native\infra\bin> ./create-secrets.sh                                        
PS C:\Users\Rafael\Desktop\Delivery-App-Cloud-Native\infra\bin> cd ..

docker build -t auth-service:latest ../backend/auth-service ; docker build -t restaurant-service:latest ../backend/restaurant-service ; docker build -t order-service:latest ../backend/order-service