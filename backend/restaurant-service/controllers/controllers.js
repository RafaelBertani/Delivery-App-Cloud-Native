const axios = require('axios');
const Joi = require('joi');
const restaurantSchema = require('../validations/restaurant.schema.js');
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

module.exports = {
    listRestaurants,
    createRestaurant
};
