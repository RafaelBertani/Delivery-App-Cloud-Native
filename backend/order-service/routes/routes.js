const { Router } = require("express");
const orderController = require('../controllers/orderControllers');
const deliveryController = require('../controllers/deliveryControllers');
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
router.get('/my-active', authMiddleware, deliveryController.getMyActiveDeliveries);
router.get('/available', authMiddleware, deliveryController.getAvailableDeliveries);

// DINÂMICAS

// Públicas

// Protegidas
router.get('/restaurant/:id', authMiddleware, orderController.getRestaurantOrders);
router.patch('/:orderId/status', authMiddleware, orderController.updateOrderStatus);
router.post('/:id/accept', authMiddleware, deliveryController.acceptDelivery);
router.post('/:id/complete', authMiddleware, deliveryController.completeDelivery);


module.exports = router;
