const asyncHandler = require('express-async-handler');
const jwt = require('jsonwebtoken');
const User = require('../models/user.model');
const LoginLog = require('../models/loginLog.model');

// Generate JWT
const generateToken = (id) => {
    return jwt.sign({ id }, process.env.JWT_SECRET, {
        expiresIn: '30d',
    });
};

// @desc    Auth user & get token
// @route   POST /api/auth/login
// @access  Public
const loginUser = asyncHandler(async (req, res) => {
    const { email, password } = req.body;

    const user = await User.findOne({ email });

    if (user && (await user.matchPassword(password))) {
        console.log(`User attempting login: ${user.email} | Role: ${user.role}`); 

        try {
            // Log the successful login
            await LoginLog.create({
                user: user._id,
                email: user.email,
                ipAddress: req.ip,
                userAgent: req.headers['user-agent'],
                status: 'success'
            });
        } catch (error) {
            console.error("Login logging failed:", error);
        }

        res.json({
            _id: user._id,
            name: user.name,
            email: user.email,
            phoneNumber: user.phoneNumber,
            role: user.role,
            token: generateToken(user._id),
        });
    } else {
        try {
            // Log failed attempt (optional, but good for security)
            await LoginLog.create({
                user: user ? user._id : null,
                email: email, 
                ipAddress: req.ip,
                userAgent: req.headers['user-agent'],
                status: 'failed'
            });
        } catch (error) {
            console.error("Login logging failed:", error);
        }

        res.status(401);
        throw new Error('Invalid email or password');
    }
});

// @desc    Register a new user (Admin Seeding)
// @route   POST /api/auth/register-admin-seeder-only
// @access  Public
const registerAdmin = asyncHandler(async (req, res) => {
    const { name, email, password } = req.body;

    const userExists = await User.findOne({ email });

    if (userExists) {
        res.status(400);
        throw new Error('User already exists');
    }

    const user = await User.create({
        name,
        email,
        password,
        role: 'admin',
        isAdmin: true
    });

    if (user) {
        res.status(201).json({
            _id: user._id,
            name: user.name,
            email: user.email,
            phoneNumber: user.phoneNumber,
            role: user.role,
            token: generateToken(user._id),
        });
    } else {
        res.status(400);
        throw new Error('Invalid user data');
    }
});

// @desc    Register a new user
// @route   POST /api/auth/register
// @access  Public
const registerUser = asyncHandler(async (req, res) => {
    const { name, email, password, phone } = req.body;

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
        phoneNumber: phone,
        role: 'farmer' // Default role for public signups
    });

    if (user) {
        res.status(201).json({
            _id: user._id,
            name: user.name,
            email: user.email,
            phoneNumber: user.phoneNumber,
            role: user.role,
            token: generateToken(user._id),
        });
    } else {
        res.status(400);
        throw new Error('Invalid user data');
    }
});

// @desc    Update user profile
// @route   PUT /api/auth/profile
// @access  Private
const updateUserProfile = asyncHandler(async (req, res) => {
    const user = await User.findById(req.user._id);

    if (user) {
        user.name = req.body.name || user.name;
        user.email = req.body.email || user.email;
        
        if (req.body.phone) {
             if (!/^\+?[0-9]+$/.test(req.body.phone)) {
                res.status(400);
                throw new Error('Phone number must contain only numbers (and optional +).');
            }
            user.phoneNumber = req.body.phone;
        } else {
            user.phoneNumber = user.phoneNumber;
        }
        
        if (req.body.password) {
            user.password = req.body.password;
        }

        const updatedUser = await user.save();

        res.json({
            _id: updatedUser._id,
            name: updatedUser.name,
            email: updatedUser.email,
            role: updatedUser.role,
            phoneNumber: updatedUser.phoneNumber,
            token: generateToken(updatedUser._id),
        });
    } else {
        res.status(404);
        throw new Error('User not found');
    }
});

module.exports = {
    loginUser,
    registerUser,
    registerAdmin,
    updateUserProfile
};
