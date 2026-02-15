const mongoose = require('mongoose');

const alertLogSchema = mongoose.Schema({
    systemName: {
        type: String,
        required: true,
        unique: true
    },
    lastAlertSent: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

module.exports = mongoose.model('AlertLog', alertLogSchema);
