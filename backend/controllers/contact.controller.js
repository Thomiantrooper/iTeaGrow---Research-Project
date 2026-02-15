const Contact = require('../models/contact.model');
const asyncHandler = require('express-async-handler');
const sendEmail = require('../utils/email');

// @desc    Submit a contact form
// @route   POST /api/contact
// @access  Public
exports.submitContactForm = async (req, res) => {
    try {
        const { name, email, message } = req.body;

        const newContact = new Contact({
            name,
            email,
            message
        });

        await newContact.save();

        res.status(201).json({ message: 'Message sent successfully!' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server Error' });
    }
};

// @desc    Get all contact messages
// @route   GET /api/contact
// @access  Private/Admin
exports.getContacts = asyncHandler(async (req, res) => {
    const contacts = await Contact.find({}).sort({ createdAt: -1 });
    res.json(contacts);
});

// @desc    Reply to a contact message
// @route   POST /api/contact/:id/reply
// @access  Private/Admin
exports.replyToContact = asyncHandler(async (req, res) => {
    const contact = await Contact.findById(req.params.id);

    if (!contact) {
        res.status(404);
        throw new Error('Contact message not found');
    }

    const { subject, message } = req.body;

    if (!subject || !message) {
        res.status(400);
        throw new Error('Please provide a subject and message');
    }

    try {
        const emailOptions = {
            email: contact.email,
            subject: subject,
            message: message, // Plain text body
            html: `
            <!DOCTYPE html>
            <html>
            <head>
                <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600&display=swap" rel="stylesheet">
                <style>
                    body { font-family: 'Poppins', sans-serif; }
                </style>
            </head>
            <body style="margin: 0; padding: 0; background-color: #f4f4f4;">
            <div style="font-family: 'Poppins', sans-serif; line-height: 1.6; color: #333; width: 100%; background-color: #f4f4f4; padding: 20px 0;">
                <div style="max-width: 100%; margin: 0 auto; background-color: #ffffff; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 6px rgba(0,0,0,0.05);">
                <div style="background-color: #21653e; color: white; padding: 25px; text-align: center;">
                    <h1 style="margin: 0; font-size: 24px; font-weight: 600;">🌱 iTeaGrow</h1>
                </div>
                <div style="padding: 35px 25px; background-color: #ffffff;">
                    <h2 style="color: #2c3e50; margin-top: 0; font-size: 20px;">Hello ${contact.name},</h2>
                    <p style="margin-bottom: 25px; color: #555;">Thank you for reaching out to the iTeaGrow support team. We have reviewed your inquiry and here is our response:</p>
                    
                    <div style="margin-bottom: 10px; font-weight: 600; color: #7f8c8d; font-size: 14px; text-transform: uppercase; letter-spacing: 1px;">Your Message / Inquiry</div>
                    <div style="background-color: #f8f9fa; padding: 15px; border-left: 4px solid #bdc3c7; border-radius: 4px; margin-bottom: 30px; color: #7f8c8d; font-style: italic;">
                        <p style="margin: 0; white-space: pre-wrap; font-size: 14px;">"${contact.message.replace(/\n/g, '<br>')}"</p>
                    </div>

                    <div style="margin-bottom: 10px; font-weight: 600; color: #7f8c8d; font-size: 14px; text-transform: uppercase; letter-spacing: 1px;">Our Response</div>
                    <div style="background-color: #f0fdf4; padding: 20px; border-left: 4px solid #27ae60; border-radius: 4px; margin-bottom: 25px;">
                        <p style="margin: 0; white-space: pre-wrap; color: #1e4620; font-size: 16px;">${message.replace(/\n/g, '<br>')}</p>
                    </div>
                    
                    <p style="color: #555;">If you have any further questions or need additional assistance, please don't hesitate to reply to this email.</p>
                    
                    <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee;">
                        <p style="margin: 0; color: #7f8c8d;">Best regards,</p>
                        <p style="margin: 5px 0 0; font-weight: 600; color: #2c3e50;">iTeaGrow Admin Team</p>
                    </div>
                </div>
                <div style="background-color: #f1f1f1; padding: 15px; text-align: center; font-size: 12px; color: #888;">
                    <p style="margin: 0;">&copy; ${new Date().getFullYear()} iTeaGrow Inc. All rights reserved.</p>
                    <p style="margin: 5px 0 0;">Empowering the Tea Industry with Smart Technology.</p>
                </div>
                </div>
            </div>
            </body>
            </html>
            ` // Professional HTML body
        };

        // Add attachment if file exists
        if (req.file) {
            emailOptions.attachments = [
                {
                    filename: req.file.originalname,
                    content: req.file.buffer
                }
            ];
        }

        try {
            await sendEmail(emailOptions);
        } catch (emailError) {
            console.error('Failed to send reply email:', emailError);
            res.status(500);
            throw new Error(`Email delivery failed: ${emailError.message}`);
        }

        // Update status to Replied and save reply history
        contact.status = 'Replied';
        contact.replies.push({
            subject: subject,
            message: message,
            // Attachments are not saved to DB to avoid potential large file issues/high storage costs
            repliedAt: Date.now()
        });

        await contact.save();

        res.json({ message: 'Reply sent successfully!' });
    } catch (error) {
        console.error(error);
        res.status(500);
        throw new Error('Email could not be sent');
    }
});
