const nodemailer = require('nodemailer');

const sendEmail = async (options) => {
    const emailUser = process.env.EMAIL_USERNAME || process.env.ADMIN_EMAIL;
    const emailPass = process.env.EMAIL_PASSWORD || process.env.ADMIN_PASSWORD;

    // Check if email credentials exist
    if (!emailUser || !emailPass) {
        console.error('Email credentials (EMAIL_USERNAME/ADMIN_EMAIL, EMAIL_PASSWORD/ADMIN_PASSWORD) are missing in .env');
        throw new Error('Server email credentials are not configured.');
    }

    // intrinsic create reusable transporter object using the default SMTP transport
    const transporter = nodemailer.createTransport({
        service: 'gmail', // Use Gmail as the service
        auth: {
            user: emailUser,
            pass: emailPass
        }
    });

    // Define email options
    const mailOptions = {
        from: `iTeaGrow Admin <${process.env.EMAIL_USERNAME}>`,
        to: options.email,
        subject: options.subject,
        text: options.message,
        html: options.html,
        attachments: options.attachments // Add attachments support
    };

    // Send email
    await transporter.sendMail(mailOptions);
};

module.exports = sendEmail;
