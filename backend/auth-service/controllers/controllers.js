const axios = require('axios');
const Joi = require('joi');
//const { getAll, findByEmail, emailExists, addUser, findUsersByCode, addAdminCodeToUser, addNonAdminCodeToUser } = require('./users');
const registerSchema = require('../validations/register.schema.js');
const loginSchema = require('../validations/login.schema.js');
const userService = require('../services/auth.service.js');
const { getSecret } = require('../middlewares/authMiddleware');
const jwt = require('jsonwebtoken');

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
      return res.status(401).json({ message: result.error });
    }

    const user = result.user;

    // Payload mínimo e seguro
    const payload = {
      sub: user.id,
      role: user.role,
      is_delivery: user.is_delivery,
      has_restaurant: user.has_restaurant
    };

    const token = jwt.sign(
      payload,
      getSecret('jwt_secret'),
      { expiresIn: process.env.JWT_EXPIRES_IN || '1d' }
    );

    return res.status(200).json({
      message: 'User logged in successfully',
      token,
      user
    });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Internal server error' });
  }
};

async function me(req, res) {
  // req.user vem do authMiddleware (payload do JWT)
  return res.status(200).json({
    user: req.user
  });
};

module.exports = {
    signup,
    signin,
    me
};
