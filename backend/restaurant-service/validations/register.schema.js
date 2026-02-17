const Joi = require('joi');

module.exports = Joi.object({
  name: Joi.string().min(3).required(),
  email: Joi.string().email({ tlds: false }).required(),
  password: Joi.string().min(6).required(),
  confirmPassword: Joi.string().valid(Joi.ref('password')).required()
});