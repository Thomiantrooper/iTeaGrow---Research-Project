
import React from 'react';
import { Leaf, Mail, Phone, MapPin, Facebook, Twitter, Linkedin, Instagram } from 'lucide-react';
import '../css/Footer.css';
import { Link } from 'react-router-dom';

const Footer = () => {
    return (
        <footer className="footer-container">
            <div className="footer-content">
                <div className="footer-section brand-section">
                    <div className="footer-logo">
                        <Leaf className="logo-icon" size={24} />
                        <span>iTeaGrow</span>
                        <img src="/symboltea1.png" alt="Tea Symbol" className="footer-logo-symbol" />
                    </div>
                    <p>
                        Empowering Ceylon Tea estates with precision agriculture, AI analytics, and sustainable IoT solutions.
                    </p>
                    <div className="social-icons">
                        <a href="#" className="social-link"><Facebook size={20} /></a>
                        <a href="#" className="social-link"><Twitter size={20} /></a>
                        <a href="#" className="social-link"><Linkedin size={20} /></a>
                        <a href="#" className="social-link"><Instagram size={20} /></a>
                    </div>
                </div>

                <div className="footer-section links-section">
                    <h4>Quick Links</h4>
                    <ul>
                        <li><Link to="/">Home</Link></li>
                        <li><Link to="/about">About Us</Link></li>
                        <li><Link to="/contact">Contact</Link></li>
                        <li><Link to="/privacy-policy">Privacy Policy</Link></li>
                        <li><Link to="/login">Login/Signup</Link></li>
                    </ul>
                </div>

                <div className="footer-section contact-section">
                    <h4>CONTACT US</h4>
                    <ul>
                        <li>
                            <MapPin size={18} /> 
                            <div>
                                <strong style={{ display: 'block', color: 'white', fontSize: '0.85rem', marginBottom: '4px' }}>Location (Research)</strong>
                                <span>Hatton, Sri Lanka</span>
                            </div>
                        </li>
                        <li>
                            <MapPin size={18} /> 
                            <div>
                                <strong style={{ display: 'block', color: 'white', fontSize: '0.85rem', marginBottom: '4px' }}>Location (Academic Site)</strong>
                                <span>Sri Lanka Institute of Information Technology, SLIIT Malabe Campus, New Kandy Rd, Malabe 10115</span>
                            </div>
                        </li>
                        <li>
                            <Mail size={18} /> 
                            <div>
                                <strong style={{ display: 'block', color: 'white', fontSize: '0.85rem', marginBottom: '4px' }}>Project Email</strong>
                                <span>research@iteagrow.com</span>
                            </div>
                        </li>
                    </ul>
                </div>
            </div>
            
            <div className="footer-bottom">
                <p>&copy; {new Date().getFullYear()} iTeaGrow. All rights reserved.</p>
            </div>
        </footer>
    );
};

export default Footer;
