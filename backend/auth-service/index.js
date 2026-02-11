const express = require('express');
const cors = require('cors');
const routes = require("./routes/routes.js");

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

app.use('/api/auth', routes);

app.listen(PORT, 'localhost', () => {
  console.log(`UserService is running on http://127.0.0.1:${PORT}`);
});