const { Pool } = require('pg');
const fs = require('fs');

const getSecret = (secretName) => {
  const path = `/run/secrets/${secretName}`;
  if (!fs.existsSync(path)) {
    throw new Error(`Secret ${secretName} não encontrado`);
  }
  return fs.readFileSync(path, 'utf8').trim();
};
// O Docker sempre monta em /run/secrets/

const pool = new Pool({
  host: 'postgres',
  port: 5432,
  user: getSecret('postgres_user'),
  password: getSecret('postgres_password'),
  database: getSecret('postgres_db_delivery')
});

module.exports = pool;