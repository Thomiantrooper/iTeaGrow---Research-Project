
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const LoginLog = require('./models/loginLog.model');
const connectDB = require('./config/db');

dotenv.config();
connectDB();

const checkLogs = async () => {
    try {
        const logs = await LoginLog.find({}).sort({ createdAt: -1 });
        console.log(`Found ${logs.length} login logs.`);
        console.log(logs);
        process.exit();
    } catch (error) {
        console.error(`Error: ${error.message}`);
        process.exit(1);
    }
};

checkLogs();
