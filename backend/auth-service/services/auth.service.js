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
}

module.exports = {
  createUser
};