const asyncHandler = require('express-async-handler');
const User = require('../models/user.model');
const bcrypt = require('bcryptjs');

// @desc    Get all users
// @route   GET /api/users
// @access  Private/Admin
const getUsers = asyncHandler(async (req, res) => {
    const users = await User.find({}).select('-password');
    res.json(users);
});

// @desc    Delete user
// @route   DELETE /api/users/:id
// @access  Private/Admin
const deleteUser = asyncHandler(async (req, res) => {
    const user = await User.findById(req.params.id);

    if (user) {
        await user.deleteOne();
        res.json({ message: 'User removed' });
    } else {
        res.status(404);
        throw new Error('User not found');
    }
});

// @desc    Create new user (Admin)
// @route   POST /api/users
// @access  Private/Admin
const createUser = asyncHandler(async (req, res) => {
    const { name, email, password, role, phone } = req.body;

    if (!name || !email || !password || !phone) {
        res.status(400);
        throw new Error('Please fill in all fields');
    }

    // Domain Validation
    const allowedDomains = ['gmail.com', 'yahoo.com', 'outlook.com', 'my.sliit.lk'];
    const emailDomain = email.split('@')[1]?.toLowerCase();

    if (!allowedDomains.includes(emailDomain)) {
        res.status(400);
        throw new Error('Please use a valid Gmail, Yahoo, Outlook, or SLIIT email address.');
    }

    if (emailDomain === 'iteagrow.com') {
        res.status(400);
        throw new Error('iteagrow.com domain is restricted.');
    }

    // Phone Number Validation
    if (phone && !/^\+?[0-9]+$/.test(phone)) {
        res.status(400);
        throw new Error('Phone number must contain only numbers (and optional +).');
    }

    const userExists = await User.findOne({ email });

    if (userExists) {
        res.status(400);
        throw new Error('User already exists');
    }

    const user = await User.create({
        name,
        email,
        password,
        role,
        phoneNumber: phone
    });

    if (user) {
        res.status(201).json({
            _id: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
            phoneNumber: user.phoneNumber
        });
    } else {
        res.status(400);
        throw new Error('Invalid user data');
    }
});

// @desc    Get user statistics
// @route   GET /api/users/stats
// @access  Private/Admin
const getUserStats = asyncHandler(async (req, res) => {
    const total = await User.countDocuments();
    
    // Get breakdown by role
    const breakdown = await User.aggregate([
        {
            $group: {
                _id: '$role',
                count: { $sum: 1 }
            }
        }
    ]);
    
    // Convert array to object for easier frontend consumption
    const roleBreakdown = {};
    breakdown.forEach(item => {
        roleBreakdown[item._id] = item.count;
    });
    
    res.json({
        total,
        breakdown: roleBreakdown
    });
});

module.exports = {
    getUsers,
    deleteUser,
    createUser,
    getUserStats
};
