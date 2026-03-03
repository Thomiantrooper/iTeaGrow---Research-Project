const express = require('express');
const router = express.Router();
const {
    getSoilData,
    getEnvIotData,
    getYieldPredictions,
    getYieldMobile,
    getYieldData,
    getMarketData,
} = require('../controllers/data.controller');

// Soil IoT: tea_soil_db → predictions
router.get('/soil', getSoilData);

// Environment IoT: iteagrow → iot_data
router.get('/env-iot', getEnvIotData);

// Yield AI Predictions: tea_yield_db → predictions (kept for legacy)
router.get('/yield-predictions', getYieldPredictions);

// Yield Mobile (kept for legacy)
router.get('/yield-mobile', getYieldMobile);

// Yield merged: both collections combined
router.get('/yield', getYieldData);

// Market/Powder AI: tea_powder_db → admin_market_value
router.get('/market', getMarketData);

module.exports = router;
