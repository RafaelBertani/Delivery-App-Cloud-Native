const addressService = require('../services/address.service');

async function getAddresses(req, res) {
  try {
    const userId = req.user.sub;
    
    const addresses = await addressService.getUserAddresses(userId);
    return res.status(200).json(addresses);
    
  } catch (error) {
    console.error('Erro ao buscar endereços:', error);
    return res.status(500).json({ message: 'Erro ao carregar endereços.' });
  }
}

async function createAddress(req, res) {
  try {
    const userId = req.user.id || req.user.sub;
    
    // Validação básica
    const { name, street, city, state, zip_code } = req.body;
    if (!name || !street || !city || !state || !zip_code) {
      return res.status(400).json({ message: 'Preencha todos os campos obrigatórios.' });
    }

    const newAddress = await addressService.createAddress(userId, req.body);
    return res.status(201).json(newAddress);
    
  } catch (error) {
    console.error('Erro ao criar endereço:', error);
    return res.status(500).json({ message: 'Erro ao salvar o endereço.' });
  }
}

async function setActiveAddress(req, res) {
  try {
    const userId = req.user.id || req.user.sub;
    const addressId = req.params.id;

    const updatedAddress = await addressService.setActiveAddress(userId, addressId);
    
    return res.status(200).json({ 
      message: 'Endereço ativado com sucesso', 
      address: updatedAddress 
    });
    
  } catch (error) {
    console.error('Erro ao ativar endereço:', error);
    if (error.message.includes('não encontrado')) {
        return res.status(404).json({ message: error.message });
    }
    return res.status(500).json({ message: 'Erro ao atualizar endereço ativo.' });
  }
}

module.exports = {
  getAddresses,
  createAddress,
  setActiveAddress
};
