const pool = require('../dbconfig/database-config');

async function getUserAddresses(userId) {
  // Ordena para que o endereço ativo apareça sempre no topo, e os mais recentes depois
  const query = `
    SELECT id, name, street, city, state, zip_code, country, is_active
    FROM addresses
    WHERE user_id = $1
    ORDER BY is_active DESC, id DESC
  `;
  try {
    const res = await pool.query(query, [userId]);
    return res.rows;
  } catch (error) {
    throw error;
  }
}

async function createAddress(userId, addressData) {
  const { name, street, city, state, zip_code, country = 'Brasil' } = addressData;
  
  // Dica de UX: Se for o primeiro endereço que o usuário cadastra, já colocamos ele como ativo!
  const checkRes = await pool.query('SELECT COUNT(*) FROM addresses WHERE user_id = $1', [userId]);
  const isFirstAddress = parseInt(checkRes.rows[0].count) === 0;

  const query = `
    INSERT INTO addresses (user_id, name, street, city, state, zip_code, country, is_active)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
    RETURNING *
  `;
  
  try {
    const res = await pool.query(query, [
      userId, name, street, city, state, zip_code, country, isFirstAddress
    ]);
    return res.rows[0];
  } catch (error) {
    throw error;
  }
}

async function setActiveAddress(userId, addressId) {
  const client = await pool.connect();
  
  try {
    // Inicia a transação: ou tudo dá certo, ou nada muda no banco
    await client.query('BEGIN');
    
    // 1. Zera tudo: desativa TODOS os endereços deste usuário
    await client.query(`
      UPDATE addresses SET is_active = FALSE WHERE user_id = $1
    `, [userId]);
    
    // 2. Ativa apenas o endereço específico que ele clicou
    const res = await client.query(`
      UPDATE addresses SET is_active = TRUE WHERE id = $1 AND user_id = $2 RETURNING *
    `, [addressId, userId]);
    
    if (res.rowCount === 0) {
      throw new Error("Endereço não encontrado ou não pertence a este usuário.");
    }

    // Se as duas queries deram certo, salva no banco!
    await client.query('COMMIT');
    return res.rows[0];

  } catch (error) {
    // Se deu erro, desfaz a bagunça
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release(); // Libera a conexão
  }
}

module.exports = {
  getUserAddresses,
  createAddress,
  setActiveAddress
};