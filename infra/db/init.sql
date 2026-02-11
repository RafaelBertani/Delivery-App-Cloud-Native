CREATE DATABASE postgres_db_delivery;
\c postgres_db_delivery

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  profile_pic BYTEA,
  joined_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  phone VARCHAR(20) NOT NULL,
  is_account_active BOOLEAN DEFAULT TRUE,
  role VARCHAR(10) CHECK (role IN ('ADM', 'USER', 'DELIVERY'))
);

CREATE INDEX idx_users_role ON users(current_role);

CREATE TABLE addresses (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  street VARCHAR(255) NOT NULL,
  city VARCHAR(100) NOT NULL,
  state VARCHAR(50) NOT NULL,
  zip_code VARCHAR(20) NOT NULL,
  country VARCHAR(50) DEFAULT 'Brasil',
  is_active BOOLEAN DEFAULT FALSE
);

CREATE UNIQUE INDEX one_active_address_per_user
ON addresses(user_id)
WHERE is_active = TRUE;

CREATE TABLE orders (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  total_amount DECIMAL(10,2) NOT NULL,
  status VARCHAR(20)
    CHECK (status IN ('PENDING','PREPARING','DELIVERING','DELIVERED','CANCELLED')),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE TABLE payment_cards (
  id SERIAL PRIMARY KEY,
  user_id INT REFERENCES users(id) ON DELETE CASCADE,
  cardholder_name VARCHAR(100) NOT NULL,
  card_number CHAR(16) NOT NULL,
  expiration_month CHAR(2) NOT NULL,
  expiration_year CHAR(4) NOT NULL,
  card_brand VARCHAR(20),
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE deliveries (
    id SERIAL PRIMARY KEY,
    order_id INT UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
    delivery_person_id INT REFERENCES users(id) ON DELETE SET NULL,
    status VARCHAR(20) DEFAULT 'WAITING_PICKUP' CHECK (status IN ('WAITING_PICKUP', 'IN_TRANSIT', 'DELIVERED', 'FAILED')),
    
    picked_up_at TIMESTAMP,
    delivered_at TIMESTAMP,
    
    current_lat DECIMAL(9,6),
    current_lng DECIMAL(9,6),
    
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_orders_updated
BEFORE UPDATE ON orders
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_deliveries_status ON deliveries(status);
