
const express = require('express');
const router = express.Router();
const contactController = require('../controllers/contact.controller');

const multer = require('multer');
const storage = multer.memoryStorage(); // Store files in memory buffer
const upload = multer({ storage: storage });

router.post('/', contactController.submitContactForm);
router.get('/', contactController.getContacts);
router.post('/:id/reply', upload.single('file'), contactController.replyToContact);

module.exports = router;
