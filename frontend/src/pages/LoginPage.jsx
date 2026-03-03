
import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { GoogleLogin } from '@react-oauth/google';
import { Leaf, Lock, Mail, ArrowRight, Home, User, Phone } from 'lucide-react';
import TeaBackground from '../components/TeaBackground';
import '../css/LoginPage.css';

const LoginPage = () => {
    const [isLogin, setIsLogin] = useState(true);
    const [formData, setFormData] = useState({
        name: '',
        email: '',
        phone: '',
        password: ''
    });
    const [error, setError] = useState('');
    const [success, setSuccess] = useState('');
    const { login, googleLogin } = useAuth();
    const navigate = useNavigate();

    const handleChange = (e) => {
        setFormData({ ...formData, [e.target.name]: e.target.value });
    };

    const handleGoogleSuccess = async (credentialResponse) => {
        setError('');
        const result = await googleLogin(credentialResponse.credential);
        if (result.success) {
            // Google login is blocked for admins at the API level (403).
            // All successful Google logins are farmers/managers → always go to home.
            navigate('/', { replace: true });
        } else {
            setError(result.message);
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError('');
        setSuccess('');

        if (isLogin) {
            const result = await login(formData.email, formData.password);
            if (result.success) {
                 // Role-based redirection
                if (result.user.role === 'admin') {
                    navigate('/admin/dashboard', { replace: true });
                } else {
                    navigate('/', { replace: true });
                }
            } else {
                setError(result.message);
            }
        } else {
            // Frontend validation (Domain check also on frontend for faster feedback)
            const allowedDomains = ['gmail.com', 'yahoo.com', 'outlook.com', 'my.sliit.lk'];
            const emailDomain = formData.email.split('@')[1]?.toLowerCase();
            
            if (!allowedDomains.includes(emailDomain)) {
                setError('Registration restricted to Gmail, Yahoo, Outlook, and SLIIT accounts.');
                return;
            }

            try {
                const response = await fetch('/api/auth/register', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(formData)
                });
                
                const contentType = response.headers.get("content-type");
                let data;
                if (contentType && contentType.indexOf("application/json") !== -1) {
                    data = await response.json();
                } else {
                    data = { message: 'Unexpected server response' };
                }
                
                if (response.ok) {
                    setSuccess('Account created! Please log in.');
                    setTimeout(() => {
                        setIsLogin(true);
                        setSuccess(''); // Clear success message or keep it? user might need to know why they are on login screen. 
                        // Let's keep a subtle indication or just clear it to avoid confusion with login success.
                        // Actually, users prefer knowing "Account created". 
                        // Let's clear it here as per standard flows, or better, set a notification.
                        // The existing success state is local to the form. 
                        // If I switch tabs, the success message might still be visible if it's outside the tab condition.
                        // Looking at the code: {success && ...} is outside the form but inside auth-card.
                        // So it will persist.
                    }, 2000);
                } else {
                    setError(data.message || 'Registration failed');
                }
            } catch (err) {
                console.error('Signup Error:', err);
                setError('Unable to connect to registration server. Please try again.');
            }
        }
    };

    return (
        <div className="login-page-wrapper">
            <TeaBackground />

            {/* Decorative Floating Symbols */}
            <Leaf className="decorative-icon" size={120} style={{ top: '10%', left: '5%', opacity: 0.03 }} />
            <Leaf className="decorative-icon" size={80} style={{ bottom: '15%', right: '8%', opacity: 0.04, animationDelay: '1s' }} />
            <Leaf className="decorative-icon" size={60} style={{ top: '40%', right: '15%', opacity: 0.02, animationDelay: '2s' }} />

            <Link to="/" className="return-home-floating">
                <Home size={18} />
                <span>Return to Home</span>
            </Link>
            
            <div className="auth-card">
                <div className="auth-header">
                    <div className="auth-logo-wrapper">
                        <Leaf size={34} />
                    </div>
                    <h1>{isLogin ? 'Login iTeaGrow' : 'Signup iTeaGrow'}</h1>
                    <p>{isLogin ? 'Secure access to your research profile' : 'Join our network of research collaborators'}</p>
                </div>

                <div className="auth-tabs">
                    <div 
                        className={`auth-tab ${isLogin ? 'active' : ''}`} 
                        onClick={() => setIsLogin(true)}
                    >
                        Login
                    </div>
                    <div 
                        className={`auth-tab ${!isLogin ? 'active' : ''}`} 
                        onClick={() => setIsLogin(false)}
                    >
                        Signup
                    </div>
                </div>

                {error && <div className="auth-error">{error}</div>}
                {success && <div className="auth-success" style={{ 
                    padding: '12px', 
                    background: 'rgba(168, 224, 99, 0.1)', 
                    color: '#a8e063', 
                    borderRadius: '12px', 
                    marginBottom: '20px',
                    textAlign: 'center',
                    fontSize: '0.9rem',
                    border: '1px solid rgba(168, 224, 99, 0.2)'
                }}>{success}</div>}

                <form className="auth-form" onSubmit={handleSubmit}>
                    {!isLogin && (
                        <>
                            <div className="input-container">
                                <label>Full Name</label>
                                <div className="input-group">
                                    <input 
                                        type="text" 
                                        name="name"
                                        placeholder="Enter your full name" 
                                        className="auth-input"
                                        value={formData.name}
                                        onChange={handleChange}
                                        required
                                    />
                                    <User className="input-icon" size={20} />
                                </div>
                            </div>
                            <div className="input-container">
                                <label>Phone Number</label>
                                <div className="input-group">
                                    <input 
                                        type="tel" 
                                        name="phone"
                                        placeholder="+94 XX XXX XXXX" 
                                        className="auth-input"
                                        value={formData.phone}
                                        onChange={handleChange}
                                        required
                                    />
                                    <Phone className="input-icon" size={20} />
                                </div>
                            </div>
                        </>
                    )}

                    <div className="input-container">
                        <label>Email Address</label>
                        <div className="input-group">
                            <input 
                                type="email" 
                                name="email"
                                placeholder="name@site.com" 
                                className="auth-input"
                                value={formData.email}
                                onChange={handleChange}
                                required
                            />
                            <Mail className="input-icon" size={20} />
                        </div>
                    </div>

                    <div className="input-container">
                        <label>Password</label>
                        <div className="input-group">
                            <input 
                                type="password" 
                                name="password"
                                placeholder="••••••••" 
                                className="auth-input"
                                value={formData.password}
                                onChange={handleChange}
                                required
                            />
                            <Lock className="input-icon" size={20} />
                        </div>
                    </div>

                    <button type="submit" className="auth-submit-btn">
                        <span>{isLogin ? 'Login' : 'Create Account'}</span>
                        <ArrowRight size={20} />
                    </button>
                </form>

                <div className="auth-divider">
                    <span>OR</span>
                </div>

                <div className="google-login-wrapper">
                    <GoogleLogin
                        onSuccess={handleGoogleSuccess}
                        onError={() => setError('Google login failed. Please try again.')}
                        theme="filled_black"
                        size="large"
                        text="continue_with"
                        shape="rectangular"
                        width="340"
                    />
                </div>
                
                {isLogin && (
                    <div style={{ 
                        padding: '16px', 
                        background: 'rgba(168, 224, 99, 0.05)', 
                        borderRadius: '16px',
                        border: '1px solid rgba(168, 224, 99, 0.1)',
                        textAlign: 'center'
                    }}>
                        <p style={{ color: '#a8e063', fontSize: '0.85rem', marginBottom: '4px', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.5px' }}>Guest Terminal:</p>
                        <p style={{ color: 'rgba(255, 255, 255, 0.5)', fontSize: '0.8rem' }}>Access with: <span style={{ color: 'white', fontWeight: 500 }}>admin@iteagrow.com</span> / <span style={{ color: 'white', fontWeight: 500 }}>admin123</span></p>
                    </div>
                )}
            </div>
        </div>
    );
};

export default LoginPage;
