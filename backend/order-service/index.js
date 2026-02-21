const express = require('express');
const cors = require('cors');
const routes = require("./routes/routes.js");
const { initRabbitMQClient } = require("./rabbitmq/rpcClient.js");

const app = express();
const PORT = process.env.PORT || 3003;

initRabbitMQClient();

app.use(cors());
app.use(express.json());

app.use('/api/orders', routes);

app.listen(PORT, '0.0.0.0', () => {
  console.log(`UserService is running on http://0.0.0.0:${PORT}`);
});