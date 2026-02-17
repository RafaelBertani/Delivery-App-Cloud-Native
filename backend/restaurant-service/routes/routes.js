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
router.get('/list', controller.list);

// 🔐 Protegidas
router.get('/me', authMiddleware, controller.me);
router.post('/new', authMiddleware, (req, res) => {
  res.json({
    message: 'Access granted',
    user: req.user
  });
});

module.exports = router;
