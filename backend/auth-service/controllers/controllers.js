const axios = require('axios');
const Joi = require('joi');
//const { getAll, findByEmail, emailExists, addUser, findUsersByCode, addAdminCodeToUser, addNonAdminCodeToUser } = require('./users');
const registerSchema = require('../validations/register.schema');

function signup(req, res) {
  const { name, email, password, confirmPassword } = req.body;

  const { error } = registerSchema.validate(
    { name, email, password, confirmPassword },
    { abortEarly: true }
  );

  if (error) {
    return res.status(400).json({
      message: error.details[0].message
    });
  }

  if (!name || !email || !password) {
    return res.status(400).json({ error: 'Name, email and password are required.' });
  }
  if (!isValidEmail(email)) {
    return res.status(400).json({ error: 'Invalid email format.' });
  }
  if (findByEmail(email)) {
    return res.status(400).json({ error: 'This email is already registered.' });
  }

  addUser({ name, email, password });
  res.status(201).json({ message: 'User created successfully.' });
}

module.exports = {
    signup
    //,
};
