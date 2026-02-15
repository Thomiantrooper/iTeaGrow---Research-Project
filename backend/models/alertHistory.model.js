const mongoose = require('mongoose');

const alertHistorySchema = mongoose.Schema({
    systemName: {
        type: String,
        required: true
    },
    issues: {
        type: [String],
        required: true
    },
    emailed: {
        type: Boolean,
        default: false
    },
    timestamp: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('AlertHistory', alertHistorySchema);
