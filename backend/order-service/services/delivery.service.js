const pool = require('../dbconfig/database-config');
const rpcClient = require('../rabbitmq/rpcClient');

// Função auxiliar para enriquecer os pedidos com o endereço do restaurante
async function populateRestaurantAddress(orders) {
  return await Promise.all(orders.map(async (order) => {
    let restAddress = 'Endereço Indisponível';
    try {
      const restInfo = await rpcClient.requestRestaurantInfo(order.restaurant_id);
      if (restInfo && restInfo.street) {
        restAddress = `${restInfo.street}, ${restInfo.city} - ${restInfo.state}`;
      }
    } catch (err) {
      console.error(`Erro ao buscar info do restaurante ${order.restaurant_id} no RabbitMQ`);
    }
    return { ...order, restaurant_address: restAddress };
  }));
}

async function completeDelivery(orderId, deliveryPersonId, code) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Verifica se o código bate e se a entrega é mesmo deste entregador
    const checkQuery = `
      SELECT o.delivery_code, d.delivery_person_id 
      FROM orders o
      JOIN deliveries d ON o.id = d.order_id
      WHERE o.id = $1
    `;
    const checkRes = await client.query(checkQuery, [orderId]);
    
    if (checkRes.rows.length === 0) throw new Error('Pedido não encontrado.');
    if (checkRes.rows[0].delivery_person_id !== deliveryPersonId) throw new Error('Você não tem permissão para concluir esta entrega.');
    if (checkRes.rows[0].delivery_code !== code) throw new Error('Código de entrega incorreto.');

    // 2. Atualiza o status do pedido para DELIVERED
    await client.query("UPDATE orders SET status = 'DELIVERED' WHERE id = $1", [orderId]);

    // 3. Atualiza a tabela de deliveries
    await client.query("UPDATE deliveries SET status = 'DELIVERED', delivered_at = CURRENT_TIMESTAMP WHERE order_id = $1", [orderId]);

    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function getActiveDeliveriesByPerson(deliveryPersonId) {
  const query = `
    SELECT o.id, o.restaurant_id, o.total_amount, o.status, 
           o.delivery_street, o.delivery_city, o.created_at
    FROM orders o
    JOIN deliveries d ON o.id = d.order_id
    WHERE d.delivery_person_id = $1 
      AND o.status IN ('PREPARED', 'DELIVERING', 'ARRIVED') 
    ORDER BY d.created_at ASC
  `;
  
  const res = await pool.query(query, [deliveryPersonId]);
  
  return await populateRestaurantAddress(res.rows);
}

async function searchAvailableDeliveries(city) {
  const query = `
    SELECT o.id, o.restaurant_id, o.total_amount, o.delivery_street, o.delivery_city, o.created_at
    FROM orders o
    LEFT JOIN deliveries d ON o.id = d.order_id
    WHERE o.status = 'PREPARED'
      AND d.id IS NULL -- Garante que nenhum motoboy pegou ainda
      AND o.delivery_city ILIKE $1
    ORDER BY o.created_at ASC
  `;
  const res = await pool.query(query, [`%${city}%`]);
  return await populateRestaurantAddress(res.rows);
}

async function acceptDelivery(orderId, deliveryPersonId) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Consulta simples: Tranca apenas a tabela orders
    const checkQuery = `SELECT status FROM orders WHERE id = $1 FOR UPDATE`;
    const checkRes = await client.query(checkQuery, [orderId]);
    
    if (checkRes.rows.length === 0) {
      throw new Error('Pedido não encontrado.');
    }
    if (checkRes.rows[0].status !== 'PREPARED') {
      throw new Error('Este pedido não está pronto para retirada.');
    }

    // 2. Tenta inserir a entrega. 
    // Se outro motoboy já pegou, a restrição UNIQUE(order_id) da tabela vai disparar um erro aqui
    const insertDeliveryQuery = `
      INSERT INTO deliveries (order_id, delivery_person_id, status, picked_up_at)
      VALUES ($1, $2, 'WAITING_PICKUP', NULL)
    `;
    await client.query(insertDeliveryQuery, [orderId, deliveryPersonId]);

    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    
    // 23505 é o código do PostgreSQL para "Unique Violation" (Duplicidade)
    if (error.code === '23505') {
      throw new Error('Ops! Outro entregador acabou de aceitar esta corrida milissegundos antes de você.');
    }
    
    throw error;
  } finally {
    client.release();
  }
}

module.exports = {
  getActiveDeliveriesByPerson,
  searchAvailableDeliveries,
  acceptDelivery,
  completeDelivery
};