const axios = require('axios');
const orderService = require('../services/order.service.js');
const { createOrderSchema } = require('../validations/createOrder.schema.js');

async function createOrder(req, res) {
  try {
    const userId = req.user.sub; // Pegamos o ID de quem está comprando pelo Token
    
    // 1. Validação do JSON de entrada
    const { error, value } = createOrderSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ message: error.details[0].message });
    }

    // 2. Passa para o Service
    const newOrder = await orderService.registerOrder(userId, value.restaurant_id, value.items);

    return res.status(201).json({
      message: 'Pedido realizado com sucesso!',
      order: newOrder
    });

  } catch (error) {
    console.error('Erro ao criar pedido:', error);
    
    // Tratamento amigável para erros conhecidos (ex: restaurante fechado, prato esgotado)
    if (error.message.includes('inválido') || error.message.includes('fechado') || error.message.includes('esgotado')) {
      return res.status(400).json({ message: error.message });
    }
    
    return res.status(500).json({ message: 'Erro interno ao processar seu pedido.' });
  }
}

module.exports = {
    createOrder
};
