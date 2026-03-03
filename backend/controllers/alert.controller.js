const asyncHandler = require('express-async-handler');
const sendEmail = require('../utils/email');
const AlertLog = require('../models/alertLog.model');
const AlertHistory = require('../models/alertHistory.model');

// @desc    Send automated system failure alert to admin
// @route   POST /api/admin/system-alert
// @access  Public (Should be protected by API key or secret in prod, but keeping it simple for now)
exports.sendSystemAlert = asyncHandler(async (req, res) => {
    const { issues, systemName } = req.body;

    if (!issues || !Array.isArray(issues) || issues.length === 0) {
        res.status(400);
        throw new Error('No issues provided for alert');
    }

    const adminEmail = process.env.ADMIN_EMAIL || process.env.EMAIL_USERNAME;

    if (!adminEmail) {
        res.status(500);
        throw new Error('Admin email not configured in .env');
    }

    // --- COOLDOWN CHECK (5 Minutes) ---
    const COOLDOWN = 5 * 60 * 1000;
    const existingLog = await AlertLog.findOne({ systemName });

    if (existingLog) {
        const timeSinceLastAlert = Date.now() - new Date(existingLog.lastAlertSent).getTime();
        if (timeSinceLastAlert < COOLDOWN) {
            // --- LOG ISSUE EVEN IF SUPPRESSED ---
            await AlertHistory.create({ systemName, issues, emailed: false });
            
            return res.status(200).json({ 
                message: `Alert suppressed (5min cooldown active). Issue logged to database.`,
                suppressed: true 
            });
        }
    }

    const issueListHtml = issues.map(issue => `
        <li style="margin-bottom: 15px; padding: 15px; background: #fff5f5; border-left: 4px solid #e74c3c; border-radius: 4px; list-style: none;">
            <strong style="color: #c0392b;">ISSUE:</strong> ${issue}
        </li>
    `).join('');

    const emailOptions = {
        email: adminEmail,
        subject: `⚠️ URGENT: iTeaGrow System Failure Detected - ${systemName || 'Multiple Systems'}`,
        message: `System issues detected: \n${issues.join('\n')}`,
        html: `
        <!DOCTYPE html>
        <html>
        <head>
            <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600&display=swap" rel="stylesheet">
            <style>
                body { font-family: 'Poppins', sans-serif; }
            </style>
        </head>
        <body style="margin: 0; padding: 0; background-color: #f7f9fc;">
            <div style="font-family: 'Poppins', sans-serif; line-height: 1.6; color: #333; width: 100%; background-color: #f7f9fc; padding: 0;">
                <div style="max-width: 100%; margin: 0 auto; background-color: #ffffff; border: none; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.1);">
                    <div style="background: linear-gradient(135deg, #e74c3c, #c0392b); color: white; padding: 30px; text-align: center;">
                        <h1 style="margin: 0; font-size: 24px;">🚨 System Alert</h1>
                        <p style="margin: 10px 0 0; opacity: 0.9;">iTeaGrow Monitoring Service</p>
                    </div>
                    <div style="padding: 30px;">
                        <h2 style="color: #2c3e50; margin-top: 0;">Critical Issues Detected</h2>
                        <p style="color: #555; line-height: 1.6;">Our automated health check has detected the following issues that require immediate attention:</p>
                        
                        <ul style="padding: 0; margin: 25px 0;">
                            ${issueListHtml}
                        </ul>

                        <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; border: 1px solid #dee2e6; margin-top: 20px;">
                            <h3 style="color: #2c3e50; font-size: 16px; margin-top: 0;">🛠 Suggested Debugging Steps:</h3>
                            <p style="font-size: 14px; color: #666; margin-bottom: 0;">
                                1. Check Railway Dashboard for cold-boot logs.<br/>
                                2. Verify CORS settings in production backend.<br/>
                                3. Ensure MongoDB Atlas cluster is reachable.<br/>
                                4. Run <code>troubleshoot</code> command in System Health dashboard.
                            </p>
                        </div>

                        <p style="color: #7f8c8d; font-size: 13px; margin-top: 30px; text-align: center;">
                            This is an automated message from the ITeaGrow Infrastructure Monitor.
                        </p>
                    </div>
                    <div style="background-color: #f1f1f1; padding: 15px; text-align: center; font-size: 12px; color: #888;">
                        &copy; ${new Date().getFullYear()} iTeaGrow Infrastructure Team
                    </div>
                </div>
            </div>
        </body>
        </html>
        `
    };

    await sendEmail(emailOptions);

    // --- UPDATE COOLDOWN LOG ---
    await AlertLog.findOneAndUpdate(
        { systemName },
        { lastAlertSent: Date.now() },
        { upsert: true, new: true }
    );

    // --- LOG SUCCESSFUL ALERT ---
    await AlertHistory.create({ systemName, issues, emailed: true });

    res.status(200).json({ message: 'Alert email sent and issue logged to database' });
});

// @desc    Get alert statistics
// @route   GET /api/admin/alert-stats
// @access  Private/Admin
exports.getAlertStats = asyncHandler(async (req, res) => {
    const last24h = new Date(Date.now() - 24 * 60 * 60 * 1000);
    
    const total = await AlertHistory.countDocuments();
    const recent = await AlertHistory.countDocuments({ 
        createdAt: { $gte: last24h } 
    });
    const emailed = await AlertHistory.countDocuments({ emailed: true });
    const suppressed = await AlertHistory.countDocuments({ emailed: false });
    
    res.json({
        total,
        last24h: recent,
        emailed,
        suppressed
    });
});

// @desc    Get recent activity feed
// @route   GET /api/admin/recent-activity
// @access  Private/Admin
exports.getRecentActivity = asyncHandler(async (req, res) => {
    const Contact = require('../models/contact.model');
    const LoginLog = require('../models/loginLog.model');
    const { getIteagrowDb } = require('../config/iteagrowDb');
    
    // Fetch web DBsources + Atlas login_logs in parallel
    const [contacts, webLogins, alerts] = await Promise.all([
        Contact.find().sort({ createdAt: -1 }).limit(3).select('name email createdAt'),
        LoginLog.find({ status: 'success' }).sort({ loginTime: -1 }).limit(4).select('email loginTime'),
        AlertHistory.find().sort({ createdAt: -1 }).limit(2).select('systemName issues createdAt'),
    ]);

    // Also pull recent logins from Atlas (mobile app logins)
    let atlasLogins = [];
    try {
        const db = await getIteagrowDb();
        atlasLogins = await db.collection('login_logs')
            .find({ success: true })
            .sort({ timestamp: -1 })
            .limit(4)
            .toArray();
    } catch (e) {
        console.warn('[Dashboard] Could not fetch Atlas login_logs:', e.message);
    }

    const activities = [
        ...contacts.map(c => ({
            type: 'contact',
            text: `New inquiry from ${c.name}`,
            email: c.email,
            time: c.createdAt
        })),
        ...webLogins.map(l => ({
            type: 'login',
            text: `Web login: ${l.email}`,
            time: l.loginTime
        })),
        ...atlasLogins.map(l => ({
            type: 'login',
            text: `Mobile login: ${l.username || l.email || 'User'}`,
            time: l.timestamp
        })),
        ...alerts.map(a => ({
            type: 'alert',
            text: `System alert: ${a.systemName || 'System'} — ${a.issues?.[0] || 'Issue detected'}`,
            time: a.createdAt
        }))
    ];
    
    activities.sort((a, b) => new Date(b.time) - new Date(a.time));
    res.json(activities.slice(0, 7));
});

// @desc    Get all alert history with filtering
// @route   GET /api/admin/alerts/history
// @access  Private/Admin
exports.getAlertHistory = asyncHandler(async (req, res) => {
    const { severity, service, dateRange, status, sort = 'newest' } = req.query;
    
    let query = {};
    
    // Filter by service
    if (service && service !== 'all') {
        query.systemName = service;
    }
    
    // Filter by date range
    if (dateRange && dateRange !== 'all') {
        const now = new Date();
        let startDate;
        
        switch(dateRange) {
            case '24h':
                startDate = new Date(now - 24 * 60 * 60 * 1000);
                break;
            case '7days':
                startDate = new Date(now - 7 * 24 * 60 * 60 * 1000);
                break;
            case '30days':
                startDate = new Date(now - 30 * 24 * 60 * 60 * 1000);
                break;
        }
        
        if (startDate) {
            query.createdAt = { $gte: startDate };
        }
    }
    
    // Determine sort order
    const sortOrder = sort === 'oldest' ? 1 : -1;
    
    // Fetch alerts
    const alerts = await AlertHistory.find(query)
        .sort({ createdAt: sortOrder })
        .select('systemName issues emailed createdAt resolved acknowledged resolvedAt')
        .lean();
    
    // Add severity based on keywords in issues
    const alertsWithMetadata = alerts.map(alert => {
        let severity = 'info';
        const issuesText = alert.issues.join(' ').toLowerCase();
        
        if (issuesText.includes('offline') || issuesText.includes('critical') || issuesText.includes('failed')) {
            severity = 'critical';
        } else if (issuesText.includes('warning') || issuesText.includes('slow') || issuesText.includes('timeout')) {
            severity = 'warning';
        }
        
        return {
            ...alert,
            severity,
            status: alert.resolved ? 'resolved' : (alert.acknowledged ? 'acknowledged' : 'active')
        };
    });
    
    // Filter by severity if specified
    let filteredAlerts = alertsWithMetadata;
    if (severity && severity !== 'all') {
        filteredAlerts = alertsWithMetadata.filter(alert => alert.severity === severity);
    }
    
    // Filter by status if specified
    if (status && status !== 'all') {
        filteredAlerts = filteredAlerts.filter(alert => alert.status === status);
    }
    
    res.json({
        count: filteredAlerts.length,
        alerts: filteredAlerts
    });
});

// @desc    Update alert status (resolve/acknowledge)
// @route   PATCH /api/admin/alerts/:id/status
// @access  Private/Admin
exports.updateAlertStatus = asyncHandler(async (req, res) => {
    const { status } = req.body;
    const alert = await AlertHistory.findById(req.params.id);

    if (!alert) {
        res.status(404);
        throw new Error('Alert not found');
    }

    if (status === 'resolved') {
        alert.resolved = true;
        alert.resolvedAt = Date.now();
        alert.resolvedBy = req.user._id;
    } else if (status === 'acknowledged') {
        alert.acknowledged = true;
    } else if (status === 'active') {
        alert.resolved = false;
        alert.acknowledged = false;
    }

    const updatedAlert = await alert.save();

    res.json({
        success: true,
        alert: {
            ...updatedAlert.toObject(),
            status: updatedAlert.resolved ? 'resolved' : (updatedAlert.acknowledged ? 'acknowledged' : 'active')
        }
    });
});
