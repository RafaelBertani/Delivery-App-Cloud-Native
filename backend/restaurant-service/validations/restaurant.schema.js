const Joi = require('joi');

const restaurantSchema = Joi.object({
  name: Joi.string().max(150).required().messages({
    'string.empty': 'O nome do restaurante é obrigatório.',
    'any.required': 'O nome do restaurante é obrigatório.'
  }),
  street: Joi.string().max(255).required().messages({
    'string.empty': 'A rua é obrigatória.',
    'any.required': 'A rua é obrigatória.'
  }),
  city: Joi.string().max(100).required().messages({
    'string.empty': 'A cidade é obrigatória.',
    'any.required': 'A cidade é obrigatória.'
  }),

  description: Joi.string().allow(null, ''),
  state: Joi.string().max(50).allow(null, ''),
  zip_code: Joi.string().max(20).allow(null, ''),
  
  country: Joi.string().max(50).default('Brasil').allow(null, ''),
  
  logo: Joi.string().allow(null, '') 
});

module.exports = restaurantSchema;