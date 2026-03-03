const asyncHandler = require('express-async-handler');
const User = require('../models/user.model');
const {
    fetchAtlasUsers,
    createAtlasUser,
    deleteAtlasUserByEmail,
} = require('../config/iteagrowDb');

// ─── helpers ──────────────────────────────────────────────────────────────────

/** Normalize a Mongoose web-app user doc to the shared shape */
function normaliseWebUser(doc) {
    return {
        _id:         doc._id?.toString(),
        name:        doc.name,
        email:       doc.email,
        role:        doc.role,
        phoneNumber: doc.phoneNumber,
        createdAt:   doc.createdAt,
        lastLogin:   doc.lastLogin || null,
        isActive:    true,
        access:      doc.access || 'both',
        googleEmail: doc.googleEmail || null,
        source:      'web',
    };
}

// ─── controllers ──────────────────────────────────────────────────────────────

// @desc    Get all users (merged from web DB + iteagrow Atlas)
// @route   GET /api/users
// @access  Private/Admin
const getUsers = asyncHandler(async (req, res) => {
    // Fetch from both sources in parallel
    const [webUsers, atlasUsers] = await Promise.all([
        User.find({}).select('-password').lean(),
        fetchAtlasUsers(),
    ]);

    const normalised = webUsers.map(normaliseWebUser);

    // Add Atlas users not already in web DB (deduplicate by email)
    const webEmails = new Set(normalised.map(u => u.email?.toLowerCase()));
    for (const au of atlasUsers) {
        const emailKey = au.email?.toLowerCase();
        if (!webEmails.has(emailKey)) {
            normalised.push(au);
        } else {
            // Same email in both — mark the web entry so the UI can show a badge
            const existing = normalised.find(
                u => u.email?.toLowerCase() === emailKey
            );
            if (existing) existing.source = 'both';
        }
    }

    res.json(normalised);
});

// @desc    Delete mobile-only user (Atlas only — no web DB record)
// @route   DELETE /api/users/by-email/:email
// @access  Private/Admin
const deleteMobileUser = asyncHandler(async (req, res) => {
    const email = decodeURIComponent(req.params.email);
    if (!email) {
        res.status(400);
        throw new Error('Email is required');
    }
    // Safety: refuse if this email also exists in web DB (use the regular delete instead)
    const webUser = await User.findOne({ email });
    if (webUser) {
        res.status(400);
        throw new Error('User exists in web DB — use the standard delete endpoint');
    }
    const deleted = await deleteAtlasUserByEmail(email);
    if (deleted) {
        res.json({ message: `Mobile user (${email}) removed from Atlas` });
    } else {
        res.status(404);
        throw new Error('User not found in Mobile DB');
    }
});

// @desc    Delete user (removes from web DB AND iteagrow Atlas)
// @route   DELETE /api/users/:id
// @access  Private/Admin
const deleteUser = asyncHandler(async (req, res) => {
    const user = await User.findById(req.params.id);

    if (user) {
        // Remove from iteagrow Atlas first (best-effort)
        await deleteAtlasUserByEmail(user.email);
        await user.deleteOne();
        res.json({ message: 'User removed from all databases' });
    } else {
        res.status(404);
        throw new Error('User not found');
    }
});

// @desc    Create new user (Admin) — writes to BOTH web DB and iteagrow Atlas
// @route   POST /api/users
// @access  Private/Admin
const createUser = asyncHandler(async (req, res) => {
    const { name, email, password, role, phone, access, googleEmail, username } = req.body;

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

    if (phone && !/^\+?[0-9]+$/.test(phone)) {
        res.status(400);
        throw new Error('Phone number must contain only numbers (and optional +).');
    }

    const userExists = await User.findOne({ email });
    if (userExists) {
        res.status(400);
        throw new Error('User already exists');
    }

    // 1. Create in web DB
    const user = await User.create({
        name, email, password, role, phoneNumber: phone,
        username: username || null,
        access: access || 'both',
        googleEmail: googleEmail || null,
    });

    // 2. Sync to iteagrow Atlas (best-effort — never fail the whole request)
    let atlasCreated = false;
    try {
        await createAtlasUser({ name, email, password, role, phone, access: access || 'both', googleEmail: googleEmail || null, username });
        atlasCreated = true;
    } catch (err) {
        console.warn('[createUser] Atlas sync failed:', err.message);
    }

    if (user) {
        res.status(201).json({
            _id:          user._id,
            name:         user.name,
            email:        user.email,
            role:         user.role,
            phoneNumber:  user.phoneNumber,
            access:       user.access,
            googleEmail:  user.googleEmail,
            createdAt:    user.createdAt,
            source:       atlasCreated ? 'both' : 'web',
            atlasCreated,
        });
    } else {
        res.status(400);
        throw new Error('Invalid user data');
    }
});

// @desc    Get user statistics
// @route   GET /api/users/stats
// @access  Private/Admin
const getUserStats = asyncHandler(async (req, res) => {
    // Fetch web DB stats + Atlas users in parallel
    const [webTotal, breakdown, atlasUsers] = await Promise.all([
        User.countDocuments(),
        User.aggregate([{ $group: { _id: '$role', count: { $sum: 1 } } }]),
        fetchAtlasUsers(),
    ]);

    const roleBreakdown = {};
    breakdown.forEach(item => { roleBreakdown[item._id] = item.count; });

    // Count Atlas-only users (not already in web DB) per role
    const webEmails = new Set(
        (await User.find({}).select('email').lean()).map(u => u.email?.toLowerCase())
    );
    let atlasOnlyCount = 0;
    for (const au of atlasUsers) {
        if (!webEmails.has(au.email?.toLowerCase())) {
            atlasOnlyCount++;
            roleBreakdown[au.role] = (roleBreakdown[au.role] || 0) + 1;
        }
    }

    res.json({ total: webTotal + atlasOnlyCount, breakdown: roleBreakdown });
});

module.exports = { getUsers, deleteUser, deleteMobileUser, createUser, getUserStats };
