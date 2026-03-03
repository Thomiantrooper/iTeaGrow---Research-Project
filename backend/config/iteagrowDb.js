/**
 * Secondary MongoDB connection to the shared `iteagrow` Atlas cluster.
 * Used to sync users between the web-app DB and the IoT / mobile-app DB.
 *
 * Connection string matches mqtt_bridge.py / database.py in the IoT API.
 */
const { MongoClient } = require('mongodb');
const bcrypt = require('bcryptjs');

const ATLAS_URI =
    process.env.ITEAGROW_ATLAS_URI;

const DB_NAME = 'iteagrow';

let _client = null;
let _db = null;

async function getIteagrowDb() {
    if (_db) return _db;
    _client = new MongoClient(ATLAS_URI, { serverSelectionTimeoutMS: 5000 });
    await _client.connect();
    _db = _client.db(DB_NAME);
    return _db;
}

/**
 * Map an iteagrow Atlas user doc → normalised shape used by the frontend.
 */
function normaliseAtlasUser(doc) {
    return {
        _id:         doc._id?.toString(),
        name:        doc.full_name || doc.username || '—',
        email:       doc.email || '—',
        role:        doc.role || 'farmer',
        phoneNumber: doc.phone || '—',
        createdAt:   doc.created_at || null,
        lastLogin:   doc.last_login || null,
        isActive:    doc.is_active !== false,
        access:      doc.access || 'both',
        googleEmail: doc.google_email || null,
        source:      'iteagrow',
    };
}

/**
 * Fetch all users from the iteagrow Atlas `users` collection.
 * Returns [] on connection failure so the main list still renders.
 */
async function fetchAtlasUsers() {
    try {
        const db = await getIteagrowDb();
        const docs = await db.collection('users').find({}).toArray();
        return docs.map(normaliseAtlasUser);
    } catch (err) {
        console.warn('[IteagrowDb] Could not fetch Atlas users:', err.message);
        return [];
    }
}

/**
 * Create a user in the iteagrow Atlas `users` collection.
 * username is derived from the email prefix (lower-cased, safe chars only)
 * unless explicitly provided.
 */
async function createAtlasUser({ name, email, password, role, phone, access, googleEmail, username }) {
    const db = await getIteagrowDb();

    const resolvedUsername = username
        ? username.toLowerCase().replace(/[^a-z0-9_]/g, '_')
        : email.split('@')[0].toLowerCase().replace(/[^a-z0-9_]/g, '_');

    const existing = await db.collection('users').findOne({ email });
    if (existing) return null; // already there – skip silently

    const hashed = await bcrypt.hash(password, 10);

    const doc = {
        username:            resolvedUsername,
        full_name:           name,
        email,
        phone:               phone || '',
        role:                role || 'farmer',
        language_preference: 'en',
        hashed_password:     hashed,
        is_active:           true,
        created_at:          new Date(),
        access:              access || 'both',
    };
    if (googleEmail) doc.google_email = googleEmail;

    const result = await db.collection('users').insertOne(doc);
    return { ...doc, _id: result.insertedId.toString() };
}

/**
 * Delete a user from the iteagrow Atlas `users` collection by email.
 */
async function deleteAtlasUserByEmail(email) {
    try {
        const db = await getIteagrowDb();
        const result = await db.collection('users').deleteOne({ email });
        return result.deletedCount > 0;
    } catch (err) {
        console.warn('[IteagrowDb] Could not delete Atlas user:', err.message);
        return false;
    }
}

module.exports = { getIteagrowDb, fetchAtlasUsers, createAtlasUser, deleteAtlasUserByEmail };
