const amqp = require('amqplib');
const fs = require('fs');
const pool = require('../dbconfig/database-config');

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
    
    const addressQueue = 'rpc_user_active_address';
    await channel.assertQueue(addressQueue, { durable: false });
    console.log(' [x] Aguardando requisições RPC em', addressQueue);

    channel.consume(addressQueue, async (msg) => {
      const userId = parseInt(msg.content.toString());
      console.log(` [.] Recebeu pedido de endereço ativo do usuário: ${userId}`);

      try {
        // Busca o endereço ativo do usuário
        const addrRes = await pool.query(
          'SELECT street, city, state, zip_code FROM addresses WHERE user_id = $1 AND is_active = TRUE LIMIT 1', 
          [userId]
        );

        let addressInfo = { error: 'Usuário não possui endereço ativo.' };
        
        if (addrRes.rows.length > 0) {
          addressInfo = addrRes.rows[0]; // Retorna { street, city, state, zip_code }
        }

        // Devolve a resposta para quem pediu (Serviço 3003)
        channel.sendToQueue(
          msg.properties.replyTo,
          Buffer.from(JSON.stringify(addressInfo)),
          { correlationId: msg.properties.correlationId }
        );
        channel.ack(msg);

      } catch (error) {
        console.error('Erro no RPC Server (Active Address):', error);
        channel.sendToQueue(
          msg.properties.replyTo,
          Buffer.from(JSON.stringify({ error: 'Erro interno ao buscar endereço' })),
          { correlationId: msg.properties.correlationId }
        );
        channel.ack(msg);
      }
    });
    
  } catch (error) {
    console.error('Falha geral ao iniciar o RabbitMQ Server:', error);
  }
}

module.exports = { startRabbitMQServer };