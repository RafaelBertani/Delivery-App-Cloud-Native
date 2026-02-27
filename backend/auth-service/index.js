const express = require('express');
const cors = require('cors');
const routes = require("./routes/routes.js");
const { startRabbitMQServer } = require("./rabbitmq/rpcServer.js");

const app = express();
const PORT = process.env.PORT || 3001;

startRabbitMQServer();

app.use(cors());
app.use(express.json());

app.use('/api/auth', routes);

// Health check endpoint
app.get('/api/auth/health', (req, res) => {
  res.status(200).json({ status: 'OK', service: 'auth-service' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`UserService is running on http://0.0.0.0:${PORT}`);
});