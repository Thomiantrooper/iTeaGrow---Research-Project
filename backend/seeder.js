
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const User = require('./models/user.model');
const connectDB = require('./config/db');

dotenv.config();
connectDB();

const importData = async () => {
    try {
        await User.deleteMany();

        const adminUser = {
            name: 'iTeaGrow Administrator',
            email: process.env.ADMIN_EMAIL,
            password: process.env.ADMIN_PASSWORD, // Will be hashed by pre-save hook
            role: 'admin',
            isAdmin: true
        };

        await User.create(adminUser);

        console.log('Admin User Seeded Successfully!');
        process.exit();
    } catch (error) {
        console.error(`Error: ${error.message}`);
        process.exit(1);
    }
};

importData();
