const nodemailer = require('nodemailer');

const sendEmail = async (options) => {
    const emailUser = process.env.EMAIL_USERNAME || process.env.ADMIN_EMAIL;
    const emailPass = process.env.EMAIL_PASSWORD || process.env.ADMIN_PASSWORD;

    // Check if email credentials exist
    if (!emailUser || !emailPass) {
        console.error('Email credentials (EMAIL_USERNAME/ADMIN_EMAIL, EMAIL_PASSWORD/ADMIN_PASSWORD) are missing in .env');
        throw new Error('Server email credentials are not configured.');
    }

    // Create reusable transporter object with Railway-optimized settings
    const transporter = nodemailer.createTransport({
        host: 'smtp.gmail.com',
        port: 587,
        secure: false, // Use STARTTLS
        auth: {
            user: emailUser,
            pass: emailPass
        },
        // Increased timeouts for Railway's network latency
        connectionTimeout: 30000, // 30 seconds (Railway can be slow)
        greetingTimeout: 30000,
        socketTimeout: 30000,
        // Connection pooling for better reliability
        pool: true,
        maxConnections: 1,
        maxMessages: 3,
        // TLS settings for cloud environments
        tls: {
            rejectUnauthorized: false,
            ciphers: 'SSLv3'
        },
        // Debug mode in development
        debug: process.env.NODE_ENV !== 'production',
        logger: process.env.NODE_ENV !== 'production'
    });

    // Define email options
    const mailOptions = {
        from: `"iTeaGrow Admin" <${emailUser}>`,
        to: options.email,
        subject: options.subject,
        text: options.message,
        html: options.html,
        attachments: options.attachments
    };

    // Send email with enhanced error handling
    try {
        const info = await transporter.sendMail(mailOptions);
        console.log('Email sent successfully:', info.messageId);
        return info;
    } catch (error) {
        console.error('Nodemailer Error Details:', error);
        
        // Provide specific error guidance
        let errorMessage = 'Email delivery failed: ';
        
        if (error.code === 'ETIMEDOUT' || error.code === 'ESOCKET') {
            errorMessage += 'Connection timeout. Gmail SMTP may be blocked on Railway. ';
            errorMessage += 'Solutions: 1) Verify App Password is correct, 2) Enable "Less secure app access" in Gmail, ';
            errorMessage += '3) Check Railway logs for network issues, 4) Consider using SendGrid/Mailgun instead of Gmail.';
        } else if (error.code === 'EAUTH') {
            errorMessage += 'Authentication failed. Check that ADMIN_PASSWORD is a valid Gmail App Password (not your regular password).';
        } else if (error.code === 'ECONNECTION') {
            errorMessage += 'Cannot connect to Gmail SMTP. Railway may be blocking outbound port 587.';
        } else {
            errorMessage += error.message;
        }
        
        throw new Error(errorMessage);
    }
};

module.exports = sendEmail;
