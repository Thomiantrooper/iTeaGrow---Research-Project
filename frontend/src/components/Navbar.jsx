
import React, { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Leaf, Menu, X, User as UserIcon, LogOut } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import '../css/Navbar.css';

const Navbar = () => {
    const { user, isAuthenticated, logout } = useAuth();
    const [scrolled, setScrolled] = useState(false);
    const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
    const location = useLocation();

    useEffect(() => {
        const handleScroll = () => {
            setScrolled(window.scrollY > 20);
        };
        window.addEventListener('scroll', handleScroll);
        return () => window.removeEventListener('scroll', handleScroll);
    }, []);

    return (
        <nav className={`navbar ${scrolled ? 'scrolled' : ''}`}>
            <div className="navbar-container">
                <Link to="/" className="navbar-logo">
                    <Leaf className="logo-icon" size={28} />
                    <span>iTeaGrow</span>
                    <img src="/symboltea1.png" alt="Tea Symbol" className="logo-symbol" />
                </Link>

                <div className="mobile-toggle" onClick={() => setMobileMenuOpen(!mobileMenuOpen)}>
                    {mobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
                </div>

                <div className={`nav-menu ${mobileMenuOpen ? 'active' : ''}`}>
                    <Link to="/" className={`nav-link ${location.pathname === '/' ? 'active' : ''}`} onClick={() => setMobileMenuOpen(false)}>Home</Link>
                    <Link to="/about" className={`nav-link ${location.pathname === '/about' ? 'active' : ''}`} onClick={() => setMobileMenuOpen(false)}>About</Link>
                    <Link to="/contact" className={`nav-link ${location.pathname === '/contact' ? 'active' : ''}`} onClick={() => setMobileMenuOpen(false)}>Contact</Link>
                    
                    {isAuthenticated ? (
                        <div className="nav-user-controls">
                            <Link to="/profile" className="nav-user-link" onClick={() => setMobileMenuOpen(false)}>
                                <UserIcon size={18} />
                                <span>{user.name}</span>
                            </Link>
                            <button onClick={logout} className="nav-logout-btn">
                                <LogOut size={18} />
                            </button>
                        </div>
                    ) : (
                        <Link to="/login" className="btn-nav-primary" onClick={() => setMobileMenuOpen(false)}>Login/Signup</Link>
                    )}
                </div>
            </div>
        </nav>
    );
};

export default Navbar;
