const mongoose = require('mongoose');

// ---------------------------------------------------------------
// Multi-Database Connection Helper
// Uses ITEAGROW_ATLAS_URI (base cluster URI) + database name
// Each connection is cached so we only connect once per database
// ---------------------------------------------------------------
const connections = {};

const getConnection = async (dbName) => {
    if (connections[dbName] && connections[dbName].readyState === 1) {
        return connections[dbName];
    }

    const baseUri = process.env.ITEAGROW_ATLAS_URI;
    if (!baseUri) throw new Error('ITEAGROW_ATLAS_URI is not defined in .env');

    // Insert the database name into the URI before the query string
    const uri = baseUri.replace('/?', `/${dbName}?`);
    const conn = await mongoose.createConnection(uri).asPromise();
    connections[dbName] = conn;
    return conn;
};

// Generic fetch: returns up to `limit` docs from a collection, most recent first
const fetchCollection = async (dbName, collectionName, limit = 200) => {
    const conn = await getConnection(dbName);
    const collection = conn.collection(collectionName);
    const docs = await collection.find({}).sort({ _id: -1 }).limit(limit).toArray();
    return docs;
};

// ---------------------------------------------------------------
// Controllers
// ---------------------------------------------------------------

// GET /api/data/soil
const getSoilData = async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 200;
        const data = await fetchCollection('tea_soil_db', 'predictions', limit);
        res.json({ source: 'tea_soil_db → predictions', count: data.length, data });
    } catch (err) {
        console.error('getSoilData error:', err);
        res.status(500).json({ error: err.message });
    }
};

// GET /api/data/env-iot
const getEnvIotData = async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 200;
        const data = await fetchCollection('iteagrow', 'iot_data', limit);
        res.json({ source: 'iteagrow → iot_data', count: data.length, data });
    } catch (err) {
        console.error('getEnvIotData error:', err);
        res.status(500).json({ error: err.message });
    }
};

// GET /api/data/yield-predictions
const getYieldPredictions = async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 200;
        const data = await fetchCollection('tea_yield_db', 'predictions', limit);
        res.json({ source: 'tea_yield_db → predictions', count: data.length, data });
    } catch (err) {
        console.error('getYieldPredictions error:', err);
        res.status(500).json({ error: err.message });
    }
};

// GET /api/data/yield-mobile
const getYieldMobile = async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 200;
        const data = await fetchCollection('iteagrow', 'tea_yield_mobile', limit);
        res.json({ source: 'iteagrow → tea_yield_mobile', count: data.length, data });
    } catch (err) {
        console.error('getYieldMobile error:', err);
        res.status(500).json({ error: err.message });
    }
};

// GET /api/data/yield  (merged: tea_yield_db → predictions + iteagrow → tea_yield_mobile)
const getYieldData = async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 200;
        const [predictions, mobile] = await Promise.all([
            fetchCollection('tea_yield_db', 'predictions', limit),
            fetchCollection('iteagrow', 'tea_yield_mobile', limit),
        ]);
        // Tag each record with its source collection so they are distinguishable
        const tagged = [
            ...predictions.map(d => ({ ...d, _source: 'tea_yield_db/predictions' })),
            ...mobile.map(d => ({ ...d, _source: 'iteagrow/tea_yield_mobile' })),
        ];
        res.json({ source: 'tea_yield_db → predictions + iteagrow → tea_yield_mobile', count: tagged.length, data: tagged });
    } catch (err) {
        console.error('getYieldData error:', err);
        res.status(500).json({ error: err.message });
    }
};

// GET /api/data/market
const getMarketData = async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 200;
        const data = await fetchCollection('tea_powder_db', 'admin_market_value', limit);
        res.json({ source: 'tea_powder_db → admin_market_value', count: data.length, data });
    } catch (err) {
        console.error('getMarketData error:', err);
        res.status(500).json({ error: err.message });
    }
};

module.exports = { getSoilData, getEnvIotData, getYieldPredictions, getYieldMobile, getYieldData, getMarketData };
