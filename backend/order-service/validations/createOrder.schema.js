const Joi = require('joi');

const createOrderSchema = Joi.object({
  restaurant_id: Joi.number().integer().positive().required(),
  
  // Exige que "items" seja um array com pelo menos 1 item dentro
  items: Joi.array().items(
    Joi.object({
      dish_id: Joi.number().integer().positive().required(),
      // Garante que ninguém mande quantidade 0 ou negativa
      quantity: Joi.number().integer().min(1).required() 
    })
  ).min(1).required()
});

module.exports = { createOrderSchema };