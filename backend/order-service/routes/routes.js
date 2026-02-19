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

// 🔓 Públicas

// 🔐 Protegidas
router.post('/create', authMiddleware, orderController.createOrder);

module.exports = router;
