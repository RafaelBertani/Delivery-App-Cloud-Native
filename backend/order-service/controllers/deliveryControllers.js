const deliveryService = require('../services/delivery.service.js');

async function getMyActiveDeliveries(req, res) {
  try {
    const deliveryPersonId = req.user.id || req.user.sub;
    const deliveries = await deliveryService.getActiveDeliveriesByPerson(deliveryPersonId);
    return res.status(200).json(deliveries);
  } catch (error) {
    console.error('Erro ao buscar minhas entregas:', error);
    return res.status(500).json({ message: 'Erro ao carregar suas entregas.' });
  }
}

async function getAvailableDeliveries(req, res) {
  try {
    const city = req.query.city;
    if (!city) {
      return res.status(400).json({ message: 'A cidade é obrigatória para a busca.' });
    }
    const deliveries = await deliveryService.searchAvailableDeliveries(city);
    return res.status(200).json(deliveries);
  } catch (error) {
    console.error('Erro ao buscar entregas disponíveis:', error);
    return res.status(500).json({ message: 'Erro ao buscar novas corridas.' });
  }
}

async function acceptDelivery(req, res) {
  try {
    const deliveryPersonId = req.user.id || req.user.sub;
    const orderId = req.params.id;
    
    await deliveryService.acceptDelivery(orderId, deliveryPersonId);
    return res.status(200).json({ message: 'Corrida aceita com sucesso!' });
  } catch (error) {
    console.error('Erro ao aceitar corrida:', error);
    return res.status(400).json({ message: error.message || 'Erro ao aceitar corrida.' });
  }
}

async function completeDelivery(req, res) {
  try {
    const deliveryPersonId = req.user.id || req.user.sub;
    const orderId = req.params.id;
    const { code } = req.body;

    if (!code) return res.status(400).json({ message: 'Código de entrega é obrigatório.' });

    await deliveryService.completeDelivery(orderId, deliveryPersonId, code);
    return res.status(200).json({ message: 'Entrega concluída com sucesso!' });
  } catch (error) {
    console.error('Erro ao concluir entrega:', error);
    return res.status(400).json({ message: error.message || 'Erro ao validar código.' });
  }
}

module.exports = {
  getMyActiveDeliveries,
  getAvailableDeliveries,
  acceptDelivery,
  completeDelivery
};