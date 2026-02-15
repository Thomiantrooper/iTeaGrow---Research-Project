
const mongoose = require('mongoose');

const contactSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true
    },
    email: {
        type: String,
        required: true
    },
    message: {
        type: String,
        required: true
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    status: {
        type: String,
        enum: ['New', 'Replied', 'Archived'],
        default: 'New'
    },
    replies: [{
        subject: String,
        message: String,
        repliedAt: {
            type: Date,
            default: Date.now
        }
    }]
});

module.exports = mongoose.model('Contact', contactSchema);
