const pool = require('../dbconfig/database-config');
const bcrypt = require('bcrypt');

async function createUser({ name, email, password }) {
  const checkQuery = 'SELECT 1 FROM users WHERE email = $1';

  try {
    const checkRes = await pool.query(checkQuery, [email]);

    if (checkRes.rows.length > 0) {
      return { error: 'This email is already registered.' };
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const role = 'USER';

    const insertQuery = `
      INSERT INTO users (name, email, password, role)
      VALUES ($1, $2, $3, $4)
      RETURNING id, name, email, profile_pic, role
    `;

    const insertValues = [name, email, hashedPassword, role];
    const insertRes = await pool.query(insertQuery, insertValues);

    return {
      user: insertRes.rows[0]
    };

  } catch (error) {
    console.error(error);
    throw error;
  }
};

async function loginUser({ email, password }) {
  const query = `
    SELECT 
      id,
      name,
      email,
      password,
      profile_pic,
      role,
      is_delivery,
      has_restaurant,
      is_account_active
    FROM users
    WHERE email = $1
  `;

  try {
    const res = await pool.query(query, [email]);

    // Usuário não encontrado
    if (res.rows.length === 0) {
      return { error: 'Invalid email or password.' };
    }

    const user = res.rows[0];

    // Conta desativada
    if (!user.is_account_active) {
      return { error: 'Account is disabled.' };
    }

    const passwordMatch = await bcrypt.compare(password, user.password);

    if (!passwordMatch) {
      return { error: 'Invalid email or password.' };
    }

    return {
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        pic: user.profile_pic,
        role: user.role,
        is_delivery: user.is_delivery,
        has_restaurant: user.has_restaurant
      }
    };

  } catch (error) {
    console.error(error);
    throw error;
  }
};

module.exports = {
  createUser,
  loginUser
};
