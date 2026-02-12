const axios = require('axios');
const Joi = require('joi');
//const { getAll, findByEmail, emailExists, addUser, findUsersByCode, addAdminCodeToUser, addNonAdminCodeToUser } = require('./users');
const registerSchema = require('../validations/register.schema.js');
const loginSchema = require('../validations/login.schema.js');
const userService = require('../services/auth.service.js');

async function signup(req, res) {
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

  try {
    const result = await userService.createUser({
      name,
      email,
      password
    });

    if (result.error) {
      return res.status(400).json({ message: result.error });
    }

    return res.status(201).json({
      message: 'User created successfully',
      user: result.user
    });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Internal server error' });
  }
};

async function signin(req, res) {
  const { email, password } = req.body;

  const { error } = loginSchema.validate(
    { email, password },
    { abortEarly: true }
  );

  if (error) {
    return res.status(400).json({
      message: error.details[0].message
    });
  }

  try {
    const result = await userService.loginUser({
      email,
      password
    });

    if (result.error) {
      return res.status(400).json({ message: result.error });
    }

    return res.status(200).json({
      message: 'User logged in successfully',
      user: result.user
    });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Internal server error' });
  }
};

module.exports = {
    signup,
    signin
};
