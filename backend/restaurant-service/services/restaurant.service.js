const pool = require('../dbconfig/database-config');
const bcrypt = require('bcrypt');

async function createNew(userId, restaurantData) {
  const { 
    name, 
    description, 
    street, 
    city, 
    state, 
    zip_code, 
    country, 
    logo // Vem como string base64 do front
  } = restaurantData;

  // 1. Converter Base64 para Buffer (para salvar como BYTEA no Postgres)
  let logoBuffer = null;
  if (logo && logo.includes('base64')) {
    // Remove o cabeçalho "data:image/png;base64,"
    const base64Data = logo.split(';base64,').pop();
    logoBuffer = Buffer.from(base64Data, 'base64');
  }

  const query = `
    INSERT INTO restaurants 
    (owner_id, name, description, logo, street, city, state, zip_code, country, is_open, is_active)
    VALUES 
    ($1, $2, $3, $4, $5, $6, $7, $8, $9, false, true)
    RETURNING id, name, is_open, created_at
  `;

  const values = [
    userId,         // $1: owner_id (Vem do Token)
    name,           // $2
    description,    // $3
    logoBuffer,     // $4: BYTEA
    street,         // $5
    city,           // $6
    state,          // $7
    zip_code,       // $8
    country || 'Brasil' // $9: Se vier vazio, usa Brasil (ou deixa o default do banco)
  ];

  try {
    const res = await pool.query(query, values);
    return res.rows[0];
  } catch (error) {
    console.error("Erro SQL createNew:", error);
    throw error;
  }
};

async function findByOwnerId( id ) {
  const query = `
    SELECT 
      id, name, description, logo, is_active, is_open, 
      created_at, street, city, state, zip_code, country 
    FROM restaurants 
    WHERE owner_id = $1
  `;

  try {
    const res = await pool.query(query, [id]);

    return res.rows; 

  } catch (error) {
    console.error('Erro ao buscar restaurantes:', error);
    throw error;
  }
};

module.exports = {
  findByOwnerId,
  createNew
};
