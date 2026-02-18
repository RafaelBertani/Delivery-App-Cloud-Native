const Joi = require('joi');

const createDishSchema = Joi.object({
  name: Joi.string().max(150).required().messages({
    'string.empty': 'O nome do prato é obrigatório.',
    'any.required': 'O nome do prato é obrigatório.'
  }),

  description: Joi.string().max(500).allow('', null),

  price: Joi.number().min(0).precision(2).required().messages({
    'number.base': 'O preço deve ser um número válido.',
    'any.required': 'O preço é obrigatório.'
  }),

  // Aceita string (Base64), null ou vazio
  image: Joi.string().allow('', null),

  // Se não vier, o banco assume TRUE, mas permite enviar false se quiser criar já esgotado
  is_available: Joi.boolean()
});

module.exports = createDishSchema;