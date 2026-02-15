const express = require('express');
const router = express.Router();
const { getUsers, deleteUser, createUser } = require('../controllers/user.controller');
const { protect, admin } = require('../middleware/authMiddleware');

router.route('/').get(protect, admin, getUsers).post(protect, admin, createUser);
router.route('/:id').delete(protect, admin, deleteUser);

module.exports = router;
