const restaurantSchema = require('../validations/restaurant.schema.js');
const restaurantUpdateSchema = require('../validations/restaurantUpdate.schema.js');
const restaurantService = require('../services/restaurant.service.js');

async function createRestaurant(req, res) {
  try {
    const userId = req.user.sub;

    const { error, value } = restaurantSchema.validate(req.body, { 
      abortEarly: true, // Para no primeiro erro
      stripUnknown: true // Remove campos que não existem no schema (segurança)
    });

    if (error) {
      return res.status(400).json({ 
        message: error.details[0].message 
      });
    }

    if (req.query.id && req.query.id !== userId) {
      return res.status(403).json({ message: 'Acesso negado.' });
    }

    const newRestaurant = await restaurantService.createNew(userId, value);

    return res.status(201).json({
      message: 'Restaurante criado com sucesso!',
      restaurant: newRestaurant
    });

  } catch (error) {
    console.error("Erro ao criar restaurante:", error);
    return res.status(500).json({ message: 'Erro interno do servidor ao criar restaurante.' });
  }
};

async function listRestaurants (req, res) {
  try {
    const userId = req.user.sub; 

    if (req.query.id && req.query.id !== userId) {
      return res.status(403).json({ message: 'Acesso negado.' });
    }

    const restaurants = await restaurantService.findByOwnerId(userId);

    return res.status(200).json(restaurants);

  } catch (error) {
    console.error("Erro ao listar restaurantes:", error);
    return res.status(500).json({ message: 'Erro interno do servidor' });
  }
};

async function manageRestaurant (req, res) {
  try {
    const userId = req.user.sub; // ID do dono (vindo do token)
    const { id } = req.params;   // ID do restaurante (vindo da URL)

    // 1. Validação Joi
    // stripUnknown: true garante que campos como "id", "created_at" ou lixo sejam removidos
    const { error, value } = restaurantUpdateSchema.validate(req.body, { 
      abortEarly: true, 
      stripUnknown: true 
    });

    if (error) {
      return res.status(400).json({ message: error.details[0].message });
    }

    // Se não sobrou nenhum campo válido para atualizar (ex: enviou objeto vazio)
    if (Object.keys(value).length === 0) {
      return res.status(400).json({ message: 'Nenhum dado válido enviado para atualização.' });
    }

    // 2. Chama o Service
    const updatedRestaurant = await restaurantService.updateRestaurant(id, userId, value);

    return res.status(200).json({
      message: 'Restaurante atualizado com sucesso!',
      restaurant: updatedRestaurant
    });

  } catch (error) {
    console.error("Erro no controller manage:", error);
    
    // Tratamento de erros específicos do Service
    if (error.message === 'Restaurante não encontrado ou permissão negada.') {
      return res.status(404).json({ message: error.message });
    }
    
    return res.status(500).json({ message: 'Erro interno ao atualizar restaurante.' });
  }
};

async function getRestaurantById (req, res) {
  try {
    const userId = req.user.sub;
    const { id } = req.params;

    // Busca no service
    const restaurant = await restaurantService.findByIdAndOwner(id, userId);

    if (!restaurant) {
      return res.status(404).json({ message: 'Restaurante não encontrado ou acesso negado.' });
    }

    // Se tiver imagem Buffer (BYTEA), converte para Base64 para o front exibir
    if (restaurant.logo) {
        restaurant.logo = `data:image/png;base64,${restaurant.logo.toString('base64')}`;
    }

    return res.status(200).json(restaurant);

  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: 'Erro ao buscar restaurante.' });
  }
};

async function getSuggestions (req, res) {
  try {
    const suggestions = await restaurantService.getTenRandomRestaurants();

    return res.status(200).json(suggestions);
  } catch (error) {
    console.error('Erro ao retornar sugestões pratos:', error);
    return res.status(500).json({ message: 'Erro ao retornar lista de sugestões.' });
  }
};

async function getRestaurantInfo (req, res) {
  try {
    const { id } = req.params;

    const restaurantInfo = await restaurantService.findRestaurantInfo(id);

    if (!restaurantInfo) {
      return res.status(404).json({ message: 'Restaurante não encontrado.' });
    }

    return res.status(200).json(restaurantInfo);

  } catch (error) {
    console.error("Erro ao acessar informações do restaurante", error);
    return res.status(500).json({ message: 'Erro interno do servidor' });
  }
};

async function searchRestaurants(req, res) {
  try {
    // Pega a variável 'q' da URL
    const searchTerm = req.query.q;

    // Se a pessoa pesquisar vazio, devolvemos um array vazio para não quebrar
    if (!searchTerm || searchTerm.trim() === '') {
      return res.status(200).json([]);
    }

    const restaurants = await restaurantService.searchRestaurants(searchTerm);
    
    return res.status(200).json(restaurants);
    
  } catch (error) {
    console.error('Erro ao pesquisar restaurantes:', error);
    return res.status(500).json({ message: 'Erro interno ao realizar a pesquisa.' });
  }
};

module.exports = {
    listRestaurants,
    createRestaurant,
    manageRestaurant,
    getRestaurantById,
    getSuggestions,
    getRestaurantInfo,
    searchRestaurants
};
