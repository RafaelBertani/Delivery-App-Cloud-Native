const { Router } = require("express");
const restaurantController = require('../controllers/restaurantControllers');
const dishController = require('../controllers/dishControllers');
const { authMiddleware } = require('../middlewares/authMiddleware');

const router = Router();

router.get("/", (req, res) => {
  res.send("OK");
});

router.get('/status', (req, res) => {
  const { code } = req.query;
  res.json({ status: getStatus(code) });
});

// ROTAS ESTÁTICAS

// Públicas
router.get('/suggested', restaurantController.getSuggestions);

// Protegidas
router.post('/new', authMiddleware, restaurantController.createRestaurant);
router.get('/list', authMiddleware, restaurantController.listRestaurants);

// ROTAS DINÂMICAS 

// Públicas
router.get('/:id/list-dishes', dishController.listDishes);
router.get('/:id', restaurantController.getRestaurantInfo);
router.get('/:id/list-all-dishes', dishController.getRestaurantDishes);

// Protegidas
router.patch('/:id/settings', authMiddleware, restaurantController.manageRestaurant);
router.get('/:id/settings', authMiddleware, restaurantController.getRestaurantById);
router.post('/:id/create-dish', authMiddleware, dishController.createDish);
router.patch('/edit-dish/:dishId', authMiddleware, dishController.updateDish);
router.delete('/delete-dish/:dishId', authMiddleware, dishController.deleteDish);

module.exports = router;
