const pool = require('../dbconfig/database-config');

// Função auxiliar para processar imagem (Base64 -> Buffer)
function processImageBuffer(base64String) {
  if (!base64String) return null;
  // Remove o prefixo "data:image/png;base64," se existir
  const base64Data = base64String.replace(/^data:image\/\w+;base64,/, "");
  return Buffer.from(base64Data, 'base64');
}

// LISTAR (Transforma Buffer -> Base64 para o front ver)
async function listByRestaurantId(restaurantId) {
  const query = `
    SELECT id, name, description, price, image, is_available 
    FROM dishes 
    WHERE restaurant_id = $1 
    ORDER BY id DESC
  `;
  
  const res = await pool.query(query, [restaurantId]);
  
  // Converte o BYTEA de volta para String Base64 para o HTML ler
  return res.rows.map(dish => {
    if (dish.image) {
      dish.image = `data:image/jpeg;base64,${dish.image.toString('base64')}`;
    }
    return dish;
  });
}

// CRIAR
async function create(userId, restaurantId, data) {
  // 1. Verificação de Segurança: O usuário é dono do restaurante?
  const checkOwner = await pool.query('SELECT id FROM restaurants WHERE id = $1 AND owner_id = $2', [restaurantId, userId]);
  if (checkOwner.rows.length === 0) {
    throw new Error('Acesso negado');
  }

  const { name, description, price, image, is_available } = data;
  const imageBuffer = processImageBuffer(image);

  const query = `
    INSERT INTO dishes (restaurant_id, name, description, price, image, is_available)
    VALUES ($1, $2, $3, $4, $5, $6)
    RETURNING id, name, price, is_available
  `;

  const values = [restaurantId, name, description, price, imageBuffer, is_available ?? true];
  
  const res = await pool.query(query, values);
  return res.rows[0];
}

// ATUALIZAR (Com SQL Dinâmico e Join para Segurança)
async function update(userId, dishId, updates) {
  // Tratamento de imagem se houver
  if (updates.image) {
    updates.image = processImageBuffer(updates.image);
  } else if (updates.image === '') {
    updates.image = null;
  }

  const fields = Object.keys(updates);
  const values = Object.values(updates);

  if (fields.length === 0) throw new Error('Nenhum dado para atualizar');

  // Monta: "name = $1, price = $2"
  const setClause = fields.map((key, i) => `${key} = $${i + 1}`).join(', ');

  // Adiciona IDs no final para o WHERE
  values.push(dishId); // index + 1
  values.push(userId); // index + 2

  // A Mágica: Fazemos UPDATE no prato (d) MAS verificamos a tabela restaurants (r)
  // para garantir que o dono do restaurante é o userId.
  const query = `
    UPDATE dishes d
    SET ${setClause}
    FROM restaurants r
    WHERE d.restaurant_id = r.id 
      AND d.id = $${values.length - 1} 
      AND r.owner_id = $${values.length}
    RETURNING d.*
  `;

  const res = await pool.query(query, values);

  if (res.rowCount === 0) {
    throw new Error('Prato não encontrado ou acesso negado');
  }

  return res.rows[0];
}

// DELETAR
async function remove(userId, dishId) {
  // Deleta SOMENTE se o restaurante dono do prato pertencer ao userId
  const query = `
    DELETE FROM dishes d
    USING restaurants r
    WHERE d.restaurant_id = r.id 
      AND d.id = $1 
      AND r.owner_id = $2
  `;

  const res = await pool.query(query, [dishId, userId]);

  if (res.rowCount === 0) {
    throw new Error('Prato não encontrado ou acesso negado');
  }
}

async function findRestaurantDishes(id) {
  // Busca os pratos do restaurante. 
  // Dica de UX: ORDER BY is_available DESC faz com que os pratos disponíveis 
  // apareçam primeiro na lista, e os esgotados fiquem no final.
  const query = `
    SELECT 
      id, 
      restaurant_id, 
      name, 
      description, 
      price, 
      image, 
      is_available 
    FROM dishes 
    WHERE restaurant_id = $1
    ORDER BY is_available DESC, name ASC
  `;

  try {
    const res = await pool.query(query, [id]);

    // Mapeia os resultados para converter o Buffer (BYTEA) em Base64
    const dishes = res.rows.map(dish => {
      if (dish.image) {
        // Converte o buffer binário para uma string base64 legível pelo navegador HTML (tag <img>)
        dish.image = `data:image/jpeg;base64,${dish.image.toString('base64')}`;
      }
      return dish;
    });

    return dishes;

  } catch (error) {
    console.error("Erro no service findRestaurantDishes:", error);
    throw error; // Lança o erro para o Controller tratar e responder com status 500
  }
}

module.exports = {
  listByRestaurantId,
  create,
  update,
  remove,
  findRestaurantDishes
};
