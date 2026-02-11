
const Contact = require('../models/contact.model');

exports.submitContactForm = async (req, res) => {
    try {
        const { name, email, message } = req.body;
        const newContact = new Contact({ name, email, message });
        await newContact.save();

        // In a real application, you would send an email here using nodemailer or similar service.
        // For now, we just save to the database.
        console.log(`New contact message from ${name} (${email}): ${message}`);

        res.status(201).json({ message: 'Message sent successfully' });
    } catch (error) {
        console.error('Error submitting contact form:', error);
        res.status(500).json({ message: 'Server error' });
    }
};
