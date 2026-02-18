const { Router } = require("express");
const controller = require('../controllers/controllers');
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
router.post('/new', authMiddleware, controller.createRestaurant);
router.get('/list', authMiddleware, controller.listRestaurants);
router.patch('/:id/settings', authMiddleware, controller.manageRestaurant);

module.exports = router;
