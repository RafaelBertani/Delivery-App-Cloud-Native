// const pool = require('../dbconfig/database-config');

// async function findByEmail(email) {
//   const query = 'SELECT * FROM users WHERE email = $1';
//   const { rows } = await pool.query(query, [email]);
//   return rows[0];
// }

// async function insertUser({ name, email, password, role }) {
//   const query = `
//     INSERT INTO users (name, email, password, role)
//     VALUES ($1, $2, $3, $4)
//     RETURNING id, name, email, profile_pic, role
//   `;

//   const values = [name, email, password, role];
//   const { rows } = await pool.query(query, values);
//   return rows[0];
// }

// module.exports = {
//   findByEmail,
//   insertUser
// };