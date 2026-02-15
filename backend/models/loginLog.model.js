
const mongoose = require('mongoose');

const loginLogSchema = mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        required: false,
        ref: 'User'
    },
    email: {
        type: String,
        required: true
    },
    ipAddress: {
        type: String,
        required: false
    },
    userAgent: {
        type: String,
        required: false
    },
    status: {
        type: String,
        enum: ['success', 'failed'],
        default: 'success'
    },
    loginTime: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

const LoginLog = mongoose.model('LoginLog', loginLogSchema);

module.exports = LoginLog;
