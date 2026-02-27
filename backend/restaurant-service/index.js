const express = require('express');
const cors = require('cors');
const routes = require("./routes/routes.js");
const { startRabbitMQServer } = require("./rabbitmq/rpcServer.js");

const app = express();
const PORT = process.env.PORT || 3002;

startRabbitMQServer();

app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/api/restaurants/health', (req, res) => {
  res.status(200).json({ status: 'OK', service: 'restaurants-service' });
});

app.use('/api/restaurants', routes);

app.listen(PORT, '0.0.0.0', () => {
  console.log(`UserService is running on http://0.0.0.0:${PORT}`);
});