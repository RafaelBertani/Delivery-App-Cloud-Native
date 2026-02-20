const dishService = require('../services/dish.service');
const createDishSchema = require('../validations/createDish.schema');
const updateDishSchema = require('../validations/updateDish.schema');

// GET /api/restaurants/:id/list-dishes (PÚBLICA)
async function listDishes (req, res) {
  try {
    const { id } = req.params; // ID do Restaurante

    const dishes = await dishService.listByRestaurantId(id);

    return res.status(200).json(dishes);
  } catch (error) {
    console.error('Erro ao listar pratos:', error);
    return res.status(500).json({ message: 'Erro ao carregar o cardápio.' });
  }
};

// POST /api/restaurants/:id/create-dish (PROTEGIDA)
async function createDish (req, res) {
  try {
    const userId = req.user.sub; // ID do Dono
    const { id } = req.params;   // ID do Restaurante
    
    // 1. Validação RÍGIDA (Create)
    // stripUnknown: true remove campos que não estão no schema (segurança)
    const { error, value } = createDishSchema.validate(req.body, { 
      abortEarly: true, 
      stripUnknown: true 
    });

    if (error) {
      return res.status(400).json({ message: error.details[0].message });
    }

    // O Service vai verificar se esse restaurante pertence ao usuário antes de criar
    // Passamos 'value' (dados validados) em vez de 'req.body'
    const newDish = await dishService.create(userId, id, value);

    return res.status(201).json(newDish);

  } catch (error) {
    console.error('Erro ao criar prato:', error);
    if (error.message === 'Acesso negado') {
      return res.status(403).json({ message: 'Você não é o dono deste restaurante.' });
    }
    return res.status(500).json({ message: 'Erro ao criar prato.' });
  }
};

// PATCH /api/restaurants/edit-dish/:dishId (PROTEGIDA)
async function updateDish (req, res) {
  try {
    const userId = req.user.sub;
    const { dishId } = req.params;
    
    // 2. Validação FLEXÍVEL (Update)
    const { error, value } = updateDishSchema.validate(req.body, { 
      abortEarly: true, 
      stripUnknown: true 
    });

    if (error) {
      return res.status(400).json({ message: error.details[0].message });
    }

    // Se o usuário mandou um JSON vazio (ou só campos inválidos que o stripUnknown removeu)
    if (Object.keys(value).length === 0) {
      return res.status(400).json({ message: 'Nenhum dado válido enviado para atualização.' });
    }

    // Passamos 'value' (dados validados)
    const updatedDish = await dishService.update(userId, dishId, value);

    return res.status(200).json(updatedDish);

  } catch (error) {
    console.error('Erro ao editar prato:', error);
    if (error.message === 'Prato não encontrado ou acesso negado') {
      return res.status(403).json({ message: error.message });
    }
    return res.status(500).json({ message: 'Erro ao atualizar prato.' });
  }
};

// DELETE /api/restaurants/delete-dish/:dishId (PROTEGIDA)
async function deleteDish (req, res) {
  try {
    const userId = req.user.sub;
    const { dishId } = req.params;

    await dishService.remove(userId, dishId);

    return res.status(204).send(); // 204 No Content (Sucesso sem corpo)

  } catch (error) {
    console.error('Erro ao deletar prato:', error);
    if (error.message === 'Prato não encontrado ou acesso negado') {
      return res.status(403).json({ message: error.message });
    }
    return res.status(500).json({ message: 'Erro ao deletar prato.' });
  }
};

async function getRestaurantDishes (req, res) {
  try {

    const { id } = req.params;

    const restaurantdishes = await dishService.findRestaurantDishes(id);

    return res.status(200).json(restaurantdishes);

  } catch (error) {
    console.error("Erro ao acessar informações do restaurante", error);
    return res.status(500).json({ message: 'Erro interno do servidor' });
  }
};

module.exports = {
    listDishes,
    createDish,
    updateDish,
    deleteDish,
    getRestaurantDishes
};
