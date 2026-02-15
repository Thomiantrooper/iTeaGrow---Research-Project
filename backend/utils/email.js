const nodemailer = require('nodemailer');

const sendEmail = async (options) => {
    const emailUser = process.env.EMAIL_USERNAME || process.env.ADMIN_EMAIL;
    const emailPass = process.env.EMAIL_PASSWORD || process.env.ADMIN_PASSWORD;

    // Check if email credentials exist
    if (!emailUser || !emailPass) {
        console.error('Email credentials (EMAIL_USERNAME/ADMIN_EMAIL, EMAIL_PASSWORD/ADMIN_PASSWORD) are missing in .env');
        throw new Error('Server email credentials are not configured.');
    }

    // Create reusable transporter object using the default SMTP transport
    const transporter = nodemailer.createTransport({
        host: 'smtp.gmail.com',
        port: 587,
        secure: false, // Use STARTTLS
        auth: {
            user: emailUser,
            pass: emailPass
        },
        // Timeout settings to prevent infinite hangs
        connectionTimeout: 10000, // 10 seconds
        greetingTimeout: 10000,
        socketTimeout: 10000,
        tls: {
            rejectUnauthorized: false
        }
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

    // Send email with catch to ensure we don't hang the parent process
    try {
        await transporter.sendMail(mailOptions);
    } catch (error) {
        console.error('Nodemailer Error Details:', error);
        throw error; // Rethrow to be caught by the controller
    }
};

module.exports = sendEmail;
