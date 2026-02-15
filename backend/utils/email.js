const nodemailer = require('nodemailer');
const sgMail = require('@sendgrid/mail');

const sendEmail = async (options) => {
    const sendgridKey = process.env.SENDGRID_API_KEY;
    const emailUser = process.env.EMAIL_USERNAME || process.env.ADMIN_EMAIL;
    const emailPass = process.env.EMAIL_PASSWORD || process.env.ADMIN_PASSWORD;

    // Use SendGrid in production (Railway), Gmail for local development
    const useSendGrid = process.env.NODE_ENV === 'production' && sendgridKey;

    if (useSendGrid) {
        // ===== SENDGRID (Production/Railway) =====
        try {
            sgMail.setApiKey(sendgridKey);
            
            const msg = {
                to: options.email,
                from: emailUser, // Must be verified in SendGrid
                subject: options.subject,
                text: options.message,
                html: options.html,
                attachments: options.attachments ? options.attachments.map(att => ({
                    content: att.content.toString('base64'),
                    filename: att.filename,
                    type: att.contentType || 'application/octet-stream',
                    disposition: 'attachment'
                })) : undefined
            };

            const response = await sgMail.send(msg);
            console.log('SendGrid email sent successfully:', response[0].statusCode);
            return response;
        } catch (error) {
            console.error('SendGrid Error:', error.response ? error.response.body : error);
            throw new Error(`SendGrid delivery failed: ${error.message}`);
        }
    } else {
        // ===== GMAIL SMTP (Local Development) =====
        if (!emailUser || !emailPass) {
            console.error('Email credentials missing in .env');
            throw new Error('Server email credentials are not configured.');
        }

        const transporter = nodemailer.createTransport({
            host: 'smtp.gmail.com',
            port: 587,
            secure: false,
            auth: { user: emailUser, pass: emailPass },
            dnsFamily: 4,
            connectionTimeout: 30000,
            greetingTimeout: 30000,
            socketTimeout: 30000,
            pool: true,
            maxConnections: 1,
            maxMessages: 3,
            tls: { rejectUnauthorized: false, ciphers: 'SSLv3' },
            debug: process.env.NODE_ENV !== 'production',
            logger: process.env.NODE_ENV !== 'production'
        });

        const mailOptions = {
            from: `"iTeaGrow Admin" <${emailUser}>`,
            to: options.email,
            subject: options.subject,
            text: options.message,
            html: options.html,
            attachments: options.attachments
        };

        try {
            const info = await transporter.sendMail(mailOptions);
            console.log('Gmail email sent successfully:', info.messageId);
            return info;
        } catch (error) {
            console.error('Gmail SMTP Error:', error);
            
            let errorMessage = 'Email delivery failed: ';
            if (error.code === 'ETIMEDOUT' || error.code === 'ESOCKET') {
                errorMessage += 'Gmail SMTP timeout. Use SendGrid for production (set SENDGRID_API_KEY in Railway).';
            } else if (error.code === 'EAUTH') {
                errorMessage += 'Gmail authentication failed. Check ADMIN_PASSWORD is a valid App Password.';
            } else {
                errorMessage += error.message;
            }
            throw new Error(errorMessage);
        }
    }
};

module.exports = sendEmail;
