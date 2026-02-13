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
router.post('/signup', controller.signup);
router.post('/signin', controller.signin);

// 🔐 Protegidas
router.get('/me', authMiddleware, controller.me);
router.get('/private', authMiddleware, (req, res) => {
  res.json({
    message: 'Access granted',
    user: req.user
  });
});

// router.get('/', controller.getUsers);
// router.post('/', controller.createUser);
// router.post('/lock-actions', controller.lockAction);
// router.post('/login', controller.login); 
// router.put('/:email', controller.upload.single('profileImage'), controller.updateUser);
// router.delete('/:email', controller.deleteUser);
// router.post('/register', controller.register);
// router.post('/join', controller.join);
// router.post('/remove-code', controller.removeCode);

module.exports = router;

// const { email } = req.body;
// const { registrationCode, email } = req.params;
