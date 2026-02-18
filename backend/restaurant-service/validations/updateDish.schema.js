const Joi = require('joi');

const updateDishSchema = Joi.object({
  name: Joi.string().max(150),
  
  description: Joi.string().max(500).allow('', null),
  
  price: Joi.number().min(0).precision(2),
  
  image: Joi.string().allow('', null),
  
  is_available: Joi.boolean()
});

module.exports = updateDishSchema;