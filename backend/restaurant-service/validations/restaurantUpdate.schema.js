const Joi = require('joi');

const restaurantUpdateSchema = Joi.object({
  name: Joi.string().max(150),
  description: Joi.string().allow('', null),
  street: Joi.string().max(255),
  city: Joi.string().max(100),
  state: Joi.string().max(50).allow('', null),
  zip_code: Joi.string().max(20).allow('', null),
  country: Joi.string().max(50),
  
  logo: Joi.string().allow('', null),
  
  is_open: Joi.boolean(),
  is_active: Joi.boolean()
});

module.exports = restaurantUpdateSchema;