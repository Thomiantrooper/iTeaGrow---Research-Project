
import React, { useState, useEffect } from 'react';
import { Mail, MapPin, Send, Github, Linkedin, CheckCircle, AlertCircle } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import '../css/ContactPage.css';

const ContactPage = () => {
    const { user } = useAuth();
    const [formData, setFormData] = useState({
        name: user?.name || '',
        email: user?.email || '',
        message: ''
    });
    const [status, setStatus] = useState({ type: '', message: '' });
    const [isSubmitting, setIsSubmitting] = useState(false);

    // Update form if user logs in/out while on page
    useEffect(() => {
        if (user) {
            setFormData(prev => ({
                ...prev,
                name: user.name,
                email: user.email
            }));
        }
    }, [user]);

    const handleChange = (e) => {
        setFormData({ ...formData, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setIsSubmitting(true);
        setStatus({ type: '', message: '' });

        try {
            const response = await fetch('/api/contact', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(formData)
            });

            const data = await response.json();

            if (response.ok) {
                setStatus({ type: 'success', message: 'Message sent! We will get back to you soon.' });
                setFormData({ ...formData, message: '' }); // Keep name/email, clear message
            } else {
                setStatus({ type: 'error', message: data.message || 'Failed to send message.' });
            }
        } catch (error) {
            console.error('Error:', error);
            setStatus({ type: 'error', message: 'Connectivity issue. Please check your network.' });
        } finally {
            setIsSubmitting(false);
        }
    };

    return (
        <div className="contact-container">
            <header className="contact-header">
                <h1>Contact us</h1>
                <p>Have inquiries about our AI models or estate integration? Our research team is ready to assist you in optimizing your harvest data.</p>
            </header>

            <div className="contact-layout">
                {/* Information Panel */}
                <div className="contact-info-panel">
                    <h2>Contact us</h2>
                    
                    <div className="location-card">
                        <div className="info-details">
                            <div className="detail-item">
                                <div className="detail-icon-wrapper">
                                    <MapPin size={22} />
                                </div>
                                <div className="detail-text">
                                    <h4>Location (Research)</h4>
                                    <p>Hatton, Sri Lanka</p>
                                </div>
                            </div>
                            <div className="detail-item">
                                <div className="detail-icon-wrapper">
                                    <MapPin size={22} />
                                </div>
                                <div className="detail-text">
                                    <h4>Location (Academic Site)</h4>
                                    <p>Sri Lanka Institute of Information Technology, SLIIT Malabe Campus, New Kandy Rd, Malabe 10115</p>
                                </div>
                            </div>
                            <div className="detail-item">
                                <div className="detail-icon-wrapper">
                                    <Mail size={22} />
                                </div>
                                <div className="detail-text">
                                    <h4>Project Email</h4>
                                    <p>research@iteagrow.com</p>
                                </div>
                            </div>
                        </div>

                        <div className="map-container">
                            <iframe 
                                className="map-iframe"
                                src="https://maps.google.com/maps?q=SLIIT%20Malabe%20Campus%2C%20New%20Kandy%20Rd%2C%20Malabe%2010115&output=embed" 
                                allowFullScreen="" 
                                loading="lazy"
                                title="SLIIT Research Center"
                            ></iframe>
                        </div>

                        <a 
                            href="https://www.google.com/maps/place/SLIIT+Malabe+Campus" 
                            target="_blank" 
                            rel="noopener noreferrer" 
                            className="google-maps-btn"
                        >
                            <span>Open in Google Maps</span>
                            <Send size={16} />
                        </a>
                    </div>

                    <div style={{ marginTop: 'auto' }}>
                        <p style={{ color: 'rgba(255,255,255,0.4)', fontSize: '0.85rem', lineHeight: '1.6' }}>
                            Our research ecosystem spans from the high-altitude estates in Hatton to the advanced computing laboratories at SLIIT Malabe.
                        </p>
                    </div>
                </div>

                {/* Form Panel */}
                <div className={`contact-form-panel ${isSubmitting ? 'submitting' : ''}`}>
                    <h2>Send a Query</h2>
                    
                    {status.message && (
                        <div className={`form-status ${status.type}`}>
                            {status.type === 'success' ? <CheckCircle size={20} /> : <AlertCircle size={20} />}
                            {status.message}
                        </div>
                    )}

                    <form className="contact-form" onSubmit={handleSubmit}>
                        <div className="input-container">
                            <label>Designation / Name</label>
                            <input
                                type="text"
                                name="name"
                                value={formData.name}
                                onChange={handleChange}
                                required
                                placeholder="Dr. Jane Perera"
                                className="contact-input"
                                disabled={!!user?.name}
                            />
                        </div>
                        <div className="input-container">
                            <label>Email Address</label>
                            <input
                                type="email"
                                name="email"
                                value={formData.email}
                                onChange={handleChange}
                                required
                                placeholder="jane@research.org"
                                className="contact-input"
                                disabled={!!user?.email}
                            />
                        </div>
                        <div className="input-container">
                            <label>Inquiry/ Message</label>
                            <textarea
                                name="message"
                                value={formData.message}
                                onChange={handleChange}
                                required
                                placeholder="Detail your research requirements or integration queries..."
                                rows="6"
                                className="contact-textarea"
                            />
                        </div>
                        <button type="submit" className="submit-btn" disabled={isSubmitting}>
                            <span>{isSubmitting ? 'Sending...' : 'Send'}</span>
                            <Send size={20} />
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default ContactPage;
