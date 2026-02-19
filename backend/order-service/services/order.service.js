const pool = require('../dbconfig/database-config');

async function registerOrder(userId, restaurantId, items) {
  // Pega uma conexão exclusiva para podermos usar transação
  const client = await pool.connect();

  try {
    // INICIA A TRANSAÇÃO: Daqui pra baixo, nada salva de verdade até o COMMIT
    await client.query('BEGIN');

    // 1. O restaurante existe e está aberto?
    const restCheck = await client.query('SELECT is_open FROM restaurants WHERE id = $1', [restaurantId]);
    if (restCheck.rows.length === 0) throw new Error('Restaurante inválido.');
    if (!restCheck.rows[0].is_open) throw new Error('O restaurante está fechado no momento.');

    let totalAmount = 0;
    const validatedItems = [];

    // 2. Percorre os itens para pegar o PREÇO REAL no banco de dados
    for (const item of items) {
      const dishRes = await client.query(
        'SELECT price, is_available FROM dishes WHERE id = $1 AND restaurant_id = $2',
        [item.dish_id, restaurantId]
      );

      // Verificações de segurança
      if (dishRes.rows.length === 0) {
        throw new Error(`Prato ID ${item.dish_id} inválido ou não pertence a este restaurante.`);
      }
      if (!dishRes.rows[0].is_available) {
        throw new Error(`Desculpe, o prato ID ${item.dish_id} acabou de esgotar.`);
      }

      const realPrice = parseFloat(dishRes.rows[0].price);
      totalAmount += realPrice * item.quantity; // Calcula o total real

      // Guarda os dados certinhos para inserir depois
      validatedItems.push({
        dish_id: item.dish_id,
        quantity: item.quantity,
        unit_price: realPrice
      });
    }

    // 3. Insere o cabeçalho do pedido (Tabela: orders)
    const orderQuery = `
      INSERT INTO orders (user_id, restaurant_id, total_amount, status) 
      VALUES ($1, $2, $3, 'PENDING') 
      RETURNING id, status, total_amount, created_at
    `;
    const orderRes = await client.query(orderQuery, [userId, restaurantId, totalAmount]);
    const newOrder = orderRes.rows[0];

    // 4. Insere cada item do pedido (Tabela: order_items)
    for (const vItem of validatedItems) {
      const itemQuery = `
        INSERT INTO order_items (order_id, dish_id, quantity, unit_price) 
        VALUES ($1, $2, $3, $4)
      `;
      await client.query(itemQuery, [newOrder.id, vItem.dish_id, vItem.quantity, vItem.unit_price]);
    }

    // 5. TUDO DEU CERTO! Confirma as alterações no banco de dados.
    await client.query('COMMIT');

    return newOrder;

  } catch (error) {
    // DEU ERRO NO MEIO DO CAMINHO? Desfaz tudo que tentamos salvar no BEGIN
    await client.query('ROLLBACK');
    throw error; 
  } finally {
    // Libera a conexão para não travar o banco
    client.release();
  }
}

module.exports = {
  registerOrder
};