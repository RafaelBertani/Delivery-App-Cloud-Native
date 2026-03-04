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

async function updateRestaurant(restaurantId, ownerId, updates) {
  
  // 1. Tratamento da Imagem (Base64 -> Buffer) se ela estiver nos updates
  if (updates.logo) {
    // Remove o cabeçalho do base64 se existir (ex: "data:image/png;base64,")
    const base64Data = updates.logo.replace(/^data:image\/\w+;base64,/, "");
    updates.logo = Buffer.from(base64Data, 'base64');
  } else if (updates.logo === null || updates.logo === '') {
    // Se o usuário mandou string vazia ou null explicitamente, salvamos null no banco
    updates.logo = null;
  }

  // 2. Construção da Query Dinâmica
  const fields = Object.keys(updates);
  const values = Object.values(updates);

  // Mapeia os campos para a sintaxe do SQL: "name = $1", "city = $2", etc.
  const setClause = fields.map((field, index) => `${field} = $${index + 1}`).join(', ');

  // Adiciona os IDs no final do array de valores para usar no WHERE
  values.push(restaurantId);
  values.push(ownerId);

  // O índice do restaurantId é (tamanho atual) - 1 + 1 (por ser base 1) = length
  // O índice do ownerId é length + 1
  const paramIndexId = values.length - 1;
  const paramIndexOwner = values.length;

  const query = `
    UPDATE restaurants 
    SET ${setClause}
    WHERE id = $${paramIndexId} AND owner_id = $${paramIndexOwner}
    RETURNING id, name, description, street, city, state, zip_code, country, is_open, is_active
  `;

  // console.log("Query:", query); // Debug se precisar
  // console.log("Values:", values);

  try {
    const res = await pool.query(query, values);

    if (res.rowCount === 0) {
      throw new Error('Restaurante não encontrado ou permissão negada.');
    }

    // Retorna o objeto atualizado (convertemos a logo de volta para base64 se necessário no futuro, 
    // mas aqui retorna sem a logo pesada para economizar banda na resposta de sucesso)
    return res.rows[0];

  } catch (error) {
    throw error;
  }
};

async function findByIdAndOwner(id, ownerId) {
  const query = `
    SELECT * FROM restaurants 
    WHERE id = $1 AND owner_id = $2
  `;

  try {
    const res = await pool.query(query, [id, ownerId]);
    return res.rows[0]; // Retorna o objeto ou undefined se não achar
  } catch (error) {
    throw error;
  }
};

async function getTenRandomRestaurants() {
  
  const query = `
    SELECT id, name, description, logo, street, city, state, is_open 
    FROM restaurants 
    ORDER BY is_open DESC, RANDOM() 
    LIMIT 10
  `;

  try {
    const res = await pool.query(query);

    // Percorre o array de resultados para converter a imagem BYTEA em Base64
    const restaurants = res.rows.map(rest => {
      if (rest.logo) {
        rest.logo = `data:image/jpeg;base64,${rest.logo.toString('base64')}`;
      }
      return rest;
    });

    return restaurants;
    
  } catch (error) {
    throw error; 
  }
  
};

async function findRestaurantInfo(id) {
  const query = `
    SELECT id, name, description, logo, street, city, state, is_open 
    FROM restaurants 
    WHERE id = $1
  `;

  try {
    const res = await pool.query(query, [id]);

    // 1. Verifica se encontrou algum restaurante com esse ID
    if (res.rowCount === 0) {
      return null; // Retorna null para o controller saber que não existe
    }

    // 2. Pega apenas o primeiro (e único) restaurante encontrado
    const restaurant = res.rows[0];

    // 3. Converte a logo de Buffer para Base64 (se existir)
    if (restaurant.logo) {
      restaurant.logo = `data:image/jpeg;base64,${restaurant.logo.toString('base64')}`;
    }

    // 4. Retorna O OBJETO (e não um array)
    return restaurant; 
    
  } catch (error) {
    throw error; 
  }
};

async function searchRestaurants(searchTerm) {
  // O ILIKE ignora maiúsculas/minúsculas.
  // Os '%' à volta do termo dizem ao banco: "pode ter qualquer texto antes ou depois desta palavra"
  const query = `
    SELECT id, name, description, logo, is_open, city, state 
    FROM restaurants 
    WHERE is_active = TRUE 
      AND name ILIKE $1 
    ORDER BY is_open DESC, name ASC
  `;
  
  // Exemplo: se o termo for "pizza", o valor passado será "%pizza%"
  const values = [`%${searchTerm}%`];

  try {
    const res = await pool.query(query, values);
    
    // Formata as logos de Buffer para Base64 (tal como fez no suggested)
    const formattedRestaurants = res.rows.map(rest => {
      if (rest.logo) {
        rest.logo = `data:image/jpeg;base64,${rest.logo.toString('base64')}`;
      }
      return rest;
    });

    return formattedRestaurants;
  } catch (error) {
    throw error;
  }
};

module.exports = {
  findByOwnerId,
  createNew,
  updateRestaurant,
  findByIdAndOwner,
  getTenRandomRestaurants,
  findRestaurantInfo,
  searchRestaurants
};
