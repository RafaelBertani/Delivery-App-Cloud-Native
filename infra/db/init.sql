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
  is_account_active BOOLEAN DEFAULT TRUE,
  role VARCHAR(10) CHECK (role IN ('ADM', 'USER')),
  is_delivery BOOLEAN DEFAULT FALSE,
  has_restaurant BOOLEAN DEFAULT FALSE
);

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

CREATE TABLE restaurants (
  id SERIAL PRIMARY KEY,
  owner_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  name VARCHAR(150) NOT NULL,
  description TEXT,
  logo BYTEA,

  is_active BOOLEAN DEFAULT TRUE,
  is_open BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  street VARCHAR(255),
  city VARCHAR(100),
  state VARCHAR(50),
  zip_code VARCHAR(20),
  country VARCHAR(50) DEFAULT 'Brasil'

);

CREATE TABLE orders (
  id SERIAL PRIMARY KEY,

  user_id INT NOT NULL
    REFERENCES users(id) ON DELETE CASCADE,

  restaurant_id INT NOT NULL
    REFERENCES restaurants(id) ON DELETE RESTRICT,

  total_amount DECIMAL(10,2) NOT NULL,

  status VARCHAR(20)
    CHECK (
      status IN (
        'PENDING',
        'PREPARING',
        'PREPARED',
        'DELIVERING',
        'ARRIVED',
        'DELIVERED',
        'CANCELLED'
      )
    ),

  pickup_code VARCHAR(3) DEFAULT LPAD(FLOOR(RANDOM() * 1000)::TEXT, 3, '0'),

  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE TABLE dishes (
  id SERIAL PRIMARY KEY,
  restaurant_id INT REFERENCES restaurants(id) ON DELETE CASCADE,

  name VARCHAR(150) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  image BYTEA,

  is_available BOOLEAN DEFAULT TRUE
);

CREATE TABLE order_items (
  id SERIAL PRIMARY KEY,
  order_id INT REFERENCES orders(id) ON DELETE CASCADE,
  dish_id INT REFERENCES dishes(id),
  quantity INT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL
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

    delivery_code VARCHAR(3) DEFAULT LPAD(FLOOR(RANDOM() * 1000)::TEXT, 3, '0'),
    
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

CREATE INDEX idx_orders_restaurant ON orders(restaurant_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_deliveries_status ON deliveries(status);
