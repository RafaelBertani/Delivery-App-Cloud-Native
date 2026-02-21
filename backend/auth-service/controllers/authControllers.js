const axios = require('axios');
const Joi = require('joi');
//const { getAll, findByEmail, emailExists, addUser, findUsersByCode, addAdminCodeToUser, addNonAdminCodeToUser } = require('./users');
const registerSchema = require('../validations/register.schema.js');
const loginSchema = require('../validations/login.schema.js');
const userService = require('../services/auth.service.js');
const { getSecret } = require('../middlewares/authMiddleware.js');
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

async function editUser(req, res) {
  try {
    const userId = req.user.sub;
    
    const updates = req.body;

    // não está vazio
    if (!updates || Object.keys(updates).length === 0) {
      return res.status(400).json({ message: 'No data provided for update.' });
    }

    // Chama o service
    const result = await userService.updateUser(userId, updates);

    return res.status(200).json({
      message: 'Profile updated successfully',
      user: result.user
    });

  } catch (err) {
    console.error(err);
    // Tratamento de erro para e-mail duplicado (código 23505 no Postgres)
    if (err.code === '23505') {
       return res.status(409).json({ message: 'Email already in use.' });
    }
    return res.status(500).json({ message: 'Error updating profile.' });
  }
};

module.exports = {
    signup,
    signin,
    me,
    editUser
};
