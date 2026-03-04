const pool = require('../dbconfig/database-config');
const rpcClient = require('../rabbitmq/rpcClient');

async function registerOrder(userId, restaurantId, items) {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // --- 1. BUSCA O ENDEREÇO VIA RABBITMQ ---
    let deliveryAddress;
    try {
      deliveryAddress = await rpcClient.requestUserActiveAddress(userId);
    } catch (err) {
      throw new Error("Você precisa ter um endereço ativo para fazer um pedido.");
    }

    // 2. Valida restaurante...
    const restCheck = await client.query('SELECT is_open FROM restaurants WHERE id = $1', [restaurantId]);
    if (restCheck.rows.length === 0) throw new Error('Restaurante inválido.');
    if (!restCheck.rows[0].is_open) throw new Error('O restaurante está fechado no momento.');

    let totalAmount = 0;
    const validatedItems = [];

    // 3. Valida itens e preços...
    for (const item of items) {
      const dishRes = await client.query('SELECT price, is_available FROM dishes WHERE id = $1 AND restaurant_id = $2', [item.dish_id, restaurantId]);
      if (dishRes.rows.length === 0) throw new Error(`Prato ID ${item.dish_id} inválido.`);
      if (!dishRes.rows[0].is_available) throw new Error(`Prato ID ${item.dish_id} esgotado.`);
      
      const realPrice = parseFloat(dishRes.rows[0].price);
      totalAmount += realPrice * item.quantity;
      validatedItems.push({ dish_id: item.dish_id, quantity: item.quantity, unit_price: realPrice });
    }

    // --- 4. INSERE O CABEÇALHO DO PEDIDO COM O ENDEREÇO COPIADO ---
    const orderQuery = `
      INSERT INTO orders (
        user_id, restaurant_id, total_amount, status, 
        delivery_street, delivery_city, delivery_state, delivery_zip_code
      ) 
      VALUES ($1, $2, $3, 'PENDING', $4, $5, $6, $7) 
      RETURNING id, status, total_amount, created_at, pickup_code
    `;
    const orderRes = await client.query(orderQuery, [
      userId, 
      restaurantId, 
      totalAmount,
      deliveryAddress.street,   // Copiado via RabbitMQ
      deliveryAddress.city,     // Copiado via RabbitMQ
      deliveryAddress.state,    // Copiado via RabbitMQ
      deliveryAddress.zip_code  // Copiado via RabbitMQ
    ]);
    const newOrder = orderRes.rows[0];

    // 5. Insere itens...
    for (const vItem of validatedItems) {
      const itemQuery = `INSERT INTO order_items (order_id, dish_id, quantity, unit_price) VALUES ($1, $2, $3, $4)`;
      await client.query(itemQuery, [newOrder.id, vItem.dish_id, vItem.quantity, vItem.unit_price]);
    }

    await client.query('COMMIT');
    return newOrder;

  } catch (error) {
    await client.query('ROLLBACK');
    throw error; 
  } finally {
    client.release();
  }
}

async function getUserOrders(userId) {
  // 1. Busca APENAS os dados da tabela orders (Sem JOIN)
  const query = `
    SELECT id, restaurant_id, total_amount, status, created_at, delivery_code 
    FROM orders 
    WHERE user_id = $1 
    ORDER BY created_at DESC
  `;

  try {
    const res = await pool.query(query, [userId]);
    const orders = res.rows;

    // 2. Para cada pedido, pede a info do restaurante via RabbitMQ
    // Promise.all para buscar todos em paralelo e ser mais rápido
    const ordersWithRestaurantData = await Promise.all(orders.map(async (order) => {
      try {
        const restInfo = await rpcClient.requestRestaurantInfo(order.restaurant_id);
        
        return {
          ...order,
          restaurant_name: restInfo ? restInfo.name : 'Restaurante Desconhecido',
          restaurant_logo: restInfo ? restInfo.logo : null
        };
      } catch (err) {
        console.error(`Erro ao buscar info do restaurante ${order.restaurant_id} no RabbitMQ`);
        return {
          ...order,
          restaurant_name: 'Restaurante Indisponível',
          restaurant_logo: null
        };
      }
    }));

    return ordersWithRestaurantData;

  } catch (error) {
    throw error;
  }
}

async function getOrdersByRestaurant(restaurantId) {
  const ordersQuery = `
    SELECT id, total_amount, status, created_at, pickup_code
    FROM orders
    WHERE restaurant_id = $1 
      AND status IN ('PENDING', 'PREPARING', 'PREPARED')
    ORDER BY created_at ASC
  `;

  try {
    const ordersRes = await pool.query(ordersQuery, [restaurantId]);
    const orders = ordersRes.rows;

    if (orders.length === 0) return [];

    // 2. Para cada pedido, vamos buscar os itens
    for (let order of orders) {
      const itemsQuery = `
        SELECT dish_id, quantity, unit_price
        FROM order_items
        WHERE order_id = $1
      `;
      const itemsRes = await pool.query(itemsQuery, [order.id]);
      
      // 3. Promise.all para buscar os nomes de todos os pratos no RabbitMQ em paralelo!
      order.items = await Promise.all(itemsRes.rows.map(async (item) => {
        let actualDishName = `Prato #${item.dish_id}`; // Valor padrão caso o RabbitMQ falhe
        
        try {
          const dishInfo = await rpcClient.requestDishInfo(item.dish_id);
          if (dishInfo && dishInfo.name) {
            actualDishName = dishInfo.name;
          }
        } catch (err) {
          console.error(`Erro ao comunicar com RabbitMQ para o prato ${item.dish_id}`);
        }

        return {
          dish_id: item.dish_id,
          quantity: item.quantity,
          unit_price: item.unit_price,
          dish_name: actualDishName
        };
      }));
    }

    return orders;
  } catch (error) {
    throw error;
  }
}

async function changeOrderStatus(orderId, newStatus) {
  // Atualiza o estado e altera o "updated_at" para a hora atual
  const query = `
    UPDATE orders 
    SET status = $1, updated_at = CURRENT_TIMESTAMP
    WHERE id = $2
    RETURNING id, status, total_amount
  `;

  try {
    const res = await pool.query(query, [newStatus, orderId]);
    
    if (res.rowCount === 0) {
      throw new Error("Pedido não encontrado.");
    }
    
    return res.rows[0];
  } catch (error) {
    throw error;
  }
}

module.exports = {
  registerOrder,
  getUserOrders,
  getOrdersByRestaurant,
  changeOrderStatus
};