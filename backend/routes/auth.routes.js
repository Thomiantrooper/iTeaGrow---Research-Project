
const express = require('express');
const router = express.Router();
const { loginUser, registerUser, registerAdmin, updateUserProfile } = require('../controllers/auth.controller');
const { protect } = require('../middleware/authMiddleware');

router.post('/login', loginUser);
router.post('/register', registerUser);
router.post('/register-admin-seeder-only', registerAdmin);
router.route('/profile').put(protect, updateUserProfile);

module.exports = router;
