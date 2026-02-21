const amqp = require('amqplib');
const restaurantService = require('../services/restaurant.service');
const fs = require('fs');

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
      console.log('⏳ [Server] Tentando conectar ao RabbitMQ...');
      const connection = await amqp.connect(getRabbitMQUrl());
      console.log('✅ [Server] Conectado ao RabbitMQ com sucesso!');
      return connection;
    } catch (error) {
      retries -= 1;
      console.log(`❌ [Server] Falha ao conectar no RabbitMQ. Tentativas restantes: ${retries}`);
      if (retries === 0) throw error;
      await sleep(5000); // Espera 5 segundos antes de tentar de novo
    }
  }
}

async function startRabbitMQServer() {
  try {
    // Chama a função com retry no lugar do amqp.connect() direto
    const connection = await connectWithRetry();
    const channel = await connection.createChannel();
    
    const queue = 'rpc_restaurant_info';
    await channel.assertQueue(queue, { durable: false });
    
    channel.prefetch(1);
    console.log(' [x] Aguardando requisições RPC em', queue);

    channel.consume(queue, async (msg) => {
      const restaurantId = parseInt(msg.content.toString());
      console.log(` [.] Recebeu pedido de info do restaurante: ${restaurantId}`);

      try {
        const restaurantInfo = await restaurantService.findRestaurantInfo(restaurantId);
        
        channel.sendToQueue(
          msg.properties.replyTo,
          Buffer.from(JSON.stringify(restaurantInfo)),
          { correlationId: msg.properties.correlationId }
        );
        
        channel.ack(msg);
      } catch (error) {
        console.error('Erro no RPC Server:', error);
        channel.sendToQueue(
          msg.properties.replyTo,
          Buffer.from(JSON.stringify({ error: 'Erro ao buscar restaurante' })),
          { correlationId: msg.properties.correlationId }
        );
        channel.ack(msg);
      }

      // === NOVA FILA: Informações do Prato ===
      const dishQueue = 'rpc_dish_info';
      await channel.assertQueue(dishQueue, { durable: false });
      
      console.log(' [x] Aguardando requisições RPC em', dishQueue);

      channel.consume(dishQueue, async (msg) => {
        const dishId = parseInt(msg.content.toString());
        
        try {
          // Faz a query direta na base de dados do restaurante para buscar o prato
          const pool = require('../dbconfig/database-config'); 
          const dishRes = await pool.query('SELECT name FROM dishes WHERE id = $1', [dishId]);
          
          let dishInfo = { name: `Prato #${dishId}` }; // Fallback
          if (dishRes.rows.length > 0) {
            dishInfo = { name: dishRes.rows[0].name };
          }

          channel.sendToQueue(
            msg.properties.replyTo,
            Buffer.from(JSON.stringify(dishInfo)),
            { correlationId: msg.properties.correlationId }
          );
          
          channel.ack(msg);
        } catch (error) {
          console.error('Erro no RPC Server (Dish Info):', error);
          channel.sendToQueue(
            msg.properties.replyTo,
            Buffer.from(JSON.stringify({ error: 'Erro ao buscar prato' })),
            { correlationId: msg.properties.correlationId }
          );
          channel.ack(msg);
        }
      });

    });
  } catch (error) {
    console.error('Falha geral ao iniciar o RabbitMQ Server:', error);
  }
}

module.exports = { startRabbitMQServer };