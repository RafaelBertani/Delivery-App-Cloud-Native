const { Router } = require("express");
const orderController = require('../controllers/orderControllers');
const { authMiddleware } = require('../middlewares/authMiddleware');

const router = Router();

router.get("/", (req, res) => {
  res.send("OK");
});

router.get('/status', (req, res) => {
  const { code } = req.query;
  res.json({ status: getStatus(code) });
});

// ESTÁTICAS

// Públicas

// Protegidas
router.post('/create', authMiddleware, orderController.createOrder);
router.get('/my-orders', authMiddleware, orderController.listMyOrders);


// DINÂMICAS

// Públicas

// Protegidas
router.get('/restaurant/:id', authMiddleware, orderController.getRestaurantOrders);
router.patch('/:orderId/status', authMiddleware, orderController.updateOrderStatus);


module.exports = router;
