const orderService = require('../services/order.service.js');
const { createOrderSchema } = require('../validations/createOrder.schema.js');

async function createOrder(req, res) {
  try {
    const userId = req.user.sub;
    
    // Validação do JSON de entrada
    const { error, value } = createOrderSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ message: error.details[0].message });
    }

    // Passa para o Service
    const newOrder = await orderService.registerOrder(userId, value.restaurant_id, value.items);

    return res.status(201).json({
      message: 'Pedido realizado com sucesso!',
      order: newOrder
    });

  } catch (error) {
    console.error('Erro ao criar pedido:', error);
    
    // Tratamento para erros conhecidos (ex: restaurante fechado, prato esgotado)
    if (error.message.includes('inválido') || error.message.includes('fechado') || error.message.includes('esgotado')) {
      return res.status(400).json({ message: error.message });
    }
    
    return res.status(500).json({ message: 'Erro interno ao processar seu pedido.' });
  }
}

async function listMyOrders(req, res) {
  try {
    const userId = req.user.sub;

    const orders = await orderService.getUserOrders(userId);

    return res.status(200).json(orders);
  } catch (error) {
    console.error('Erro ao listar pedidos do usuário:', error);
    return res.status(500).json({ message: 'Erro interno ao buscar histórico de pedidos.' });
  }
}

async function getRestaurantOrders(req, res) {
  try {
    const { id } = req.params;
        
    const orders = await orderService.getOrdersByRestaurant(id);
    return res.status(200).json(orders);
    
  } catch (error) {
    console.error('Erro ao buscar pedidos do restaurante:', error);
    return res.status(500).json({ message: 'Erro ao carregar os pedidos do restaurante.' });
  }
}

async function updateOrderStatus(req, res) {
  try {
    const { orderId } = req.params;
    const { status } = req.body;

    if (!status) {
      return res.status(400).json({ message: 'O novo estado (status) é obrigatório.' });
    }

    const updatedOrder = await orderService.changeOrderStatus(orderId, status);
    
    return res.status(200).json({
      message: 'Estado do pedido atualizado com sucesso!',
      order: updatedOrder
    });
    
  } catch (error) {
    console.error('Erro ao atualizar estado do pedido:', error);
    return res.status(500).json({ message: 'Erro ao atualizar o estado do pedido.' });
  }
}

module.exports = {
    createOrder,
    listMyOrders,
    getRestaurantOrders,
    updateOrderStatus
};
