const amqp = require('amqplib');
const crypto = require('crypto');
const fs = require('fs');

let channel;
let replyQueue;
const eventEmitter = new (require('events'))();

// Função auxiliar para esperar
const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

function getRabbitMQUrl() {
  const user = process.env.RABBITMQ_USER_FILE 
    ? fs.readFileSync(process.env.RABBITMQ_USER_FILE, 'utf8').trim() 
    : 'guest'; 

  const pass = process.env.RABBITMQ_PASSWORD_FILE 
    ? fs.readFileSync(process.env.RABBITMQ_PASSWORD_FILE, 'utf8').trim() 
    : 'guest';

  const host = process.env.RABBITMQ_HOST || 'localhost';
  const port = process.env.RABBITMQ_PORT || '5672';

  return `amqp://${user}:${pass}@${host}:${port}`;
}

// Nova função com loop de tentativas
async function connectWithRetry() {
  let retries = 10;
  while (retries > 0) {
    try {
      console.log('⏳ [Client] Tentando conectar ao RabbitMQ...');
      const connection = await amqp.connect(getRabbitMQUrl());
      console.log('✅ [Client] Conectado ao RabbitMQ com sucesso!');
      return connection;
    } catch (error) {
      retries -= 1;
      console.log(`❌ [Client] Falha ao conectar no RabbitMQ. Tentativas restantes: ${retries}`);
      if (retries === 0) throw error;
      await sleep(5000); // Espera 5 segundos antes de tentar de novo
    }
  }
}

async function initRabbitMQClient() {
  // Chama a função com retry no lugar do amqp.connect() direto
  const connection = await connectWithRetry();
  channel = await connection.createChannel();
  
  const q = await channel.assertQueue('', { exclusive: true });
  replyQueue = q.queue;

  channel.consume(replyQueue, (msg) => {
    if (msg) {
      eventEmitter.emit(msg.properties.correlationId, JSON.parse(msg.content.toString()));
    }
  }, { noAck: true });
  
  console.log(' [x] RabbitMQ RPC Client pronto para uso.');
}

async function requestRestaurantInfo(restaurantId) {
  if (!channel) await initRabbitMQClient();

  return new Promise((resolve, reject) => {
    const correlationId = crypto.randomUUID();

    eventEmitter.once(correlationId, (response) => {
      if (response && response.error) {
        reject(new Error(response.error));
      } else {
        resolve(response);
      }
    });

    channel.sendToQueue(
      'rpc_restaurant_info',
      Buffer.from(restaurantId.toString()),
      {
        correlationId: correlationId,
        replyTo: replyQueue
      }
    );
  });
}

async function requestDishInfo(dishId) {
  if (!channel) await initRabbitMQClient();

  return new Promise((resolve, reject) => {
    const correlationId = crypto.randomUUID();

    eventEmitter.once(correlationId, (response) => {
      if (response && response.error) {
        reject(new Error(response.error));
      } else {
        resolve(response);
      }
    });

    channel.sendToQueue(
      'rpc_dish_info', // <--- Nova fila específica para pratos
      Buffer.from(dishId.toString()),
      {
        correlationId: correlationId,
        replyTo: replyQueue
      }
    );
  });
}

async function requestUserActiveAddress(userId) {
  if (!channel) await initRabbitMQClient();

  return new Promise((resolve, reject) => {
    const correlationId = crypto.randomUUID();

    eventEmitter.once(correlationId, (response) => {
      if (response && response.error) {
        reject(new Error(response.error));
      } else {
        resolve(response);
      }
    });

    // Envia o pedido para a nova fila que o 3001 está escutando
    channel.sendToQueue(
      'rpc_user_active_address',
      Buffer.from(userId.toString()),
      {
        correlationId: correlationId,
        replyTo: replyQueue
      }
    );
  });
}

module.exports = { initRabbitMQClient, requestRestaurantInfo, requestDishInfo, requestUserActiveAddress };