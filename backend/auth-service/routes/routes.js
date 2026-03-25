const { Router } = require("express");
const authController = require('../controllers/authControllers');
const addressController = require('../controllers/addressControllers');
const { authMiddleware } = require('../middlewares/authMiddleware');

const router = Router();

router.get("/", (req, res) => {
  res.send("OK");
});

router.get('/status', (req, res) => {
  const { code } = req.query;
  res.json({ status: getStatus(code) });
});

// Públicas
router.post('/signup', authController.signup);
router.post('/signin', authController.signin);

// Protegidas
router.get('/me', authMiddleware, authController.me);
router.get('/private', authMiddleware, (req, res) => {
  res.json({
    message: 'Access granted',
    user: req.user
  });
});
router.put('/edit', authMiddleware, authController.editUser);
router.get('/addresses', authMiddleware, addressController.getAddresses);
router.post('/addresses', authMiddleware, addressController.createAddress);
router.put('/addresses/:id/active', authMiddleware, addressController.setActiveAddress); //dinâmica

module.exports = router;

// const { email } = req.body;
// const { registrationCode, email } = req.params;
