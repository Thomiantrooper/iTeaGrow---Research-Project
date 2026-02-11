
import React, { useState, useEffect } from 'react';
import { useAuth } from '../context/AuthContext';
import { User, Phone, Lock, Save, ArrowLeft, CheckCircle, AlertCircle } from 'lucide-react';
import { Link } from 'react-router-dom';
import '../css/ProfilePage.css';

const ProfilePage = () => {
    const { user, updateProfile } = useAuth();
    const [formData, setFormData] = useState({
        name: user?.name || '',
        phone: user?.phoneNumber || '',
        currentPassword: '',
        newPassword: '',
        confirmPassword: ''
    });
    const [status, setStatus] = useState({ type: '', message: '' });
    const [isSubmitting, setIsSubmitting] = useState(false);

    useEffect(() => {
        if (user) {
            setFormData(prev => ({
                ...prev,
                name: user.name,
                phone: user.phoneNumber || ''
            }));
        }
    }, [user]);

    const handleChange = (e) => {
        setFormData({ ...formData, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setStatus({ type: '', message: '' });

        if (formData.newPassword && formData.newPassword !== formData.confirmPassword) {
            setStatus({ type: 'error', message: 'New passwords do not match' });
            return;
        }

        setIsSubmitting(true);
        const result = await updateProfile({
            name: formData.name,
            phone: formData.phone,
            password: formData.newPassword || undefined
        });

        if (result.success) {
            setStatus({ type: 'success', message: 'Profile updated successfully!' });
            setFormData(prev => ({ ...prev, currentPassword: '', newPassword: '', confirmPassword: '' }));
        } else {
            setStatus({ type: 'error', message: result.message });
        }
        setIsSubmitting(false);
    };

    return (
        <div className="profile-container">
            <div className="profile-header">
                <Link to="/" className="back-link">
                    <ArrowLeft size={18} />
                    <span>Back to Dashboard</span>
                </Link>
                <h1>My Profile</h1>
                <p>Manage your account settings and research identity</p>
            </div>

            <div className="profile-content">
                <div className="profile-card glass-panel">
                    <div className="profile-user-info">
                        <div className="avatar-placeholder">
                            <User size={40} />
                        </div>
                        <div className="user-text">
                            <h3>{user?.name}</h3>
                            <span>{user?.email}</span>
                        </div>
                    </div>

                    <form className="profile-form" onSubmit={handleSubmit}>
                        {/* Hidden input to trap browser autofill for username */}
                        <input 
                            type="text" 
                            name="username" 
                            autoComplete="username" 
                            value={user?.email} 
                            readOnly
                            style={{ opacity: 0, position: 'absolute', zIndex: -1, height: 0, width: 0 }} 
                        />

                        {status.message && (
                            <div className={`status-message ${status.type}`}>
                                {status.type === 'success' ? <CheckCircle size={18} /> : <AlertCircle size={18} />}
                                <span>{status.message}</span>
                            </div>
                        )}

                        <div className="form-grid">
                            <div className="input-container">
                                <label>Full Name</label>
                                <div className="input-group">
                                    <input 
                                        type="text" 
                                        name="name"
                                        value={formData.name}
                                        onChange={handleChange}
                                        placeholder="Enter your full name"
                                        autoComplete="name"
                                        required
                                    />
                                    <User size={18} />
                                </div>
                            </div>

                            <div className="input-container">
                                <label>Phone Number</label>
                                <div className="input-group">
                                    <input 
                                        type="tel" 
                                        name="phone"
                                        value={formData.phone}
                                        onChange={handleChange}
                                        placeholder="+94 XX XXX XXXX"
                                        autoComplete="tel"
                                    />
                                    <Phone size={18} />
                                </div>
                            </div>
                        </div>

                        <div className="password-section">
                            <h4>Security Settings</h4>
                            <p>Leave password fields blank if you don't want to change it</p>

                            <div className="form-grid">
                                <div className="input-container">
                                    <label>New Password</label>
                                    <div className="input-group">
                                        <input 
                                            type="password" 
                                            name="newPassword"
                                            value={formData.newPassword}
                                            onChange={handleChange}
                                            placeholder="••••••••"
                                            autoComplete="new-password"
                                        />
                                        <Lock size={18} />
                                    </div>
                                </div>

                                <div className="input-container">
                                    <label>Confirm Password</label>
                                    <div className="input-group">
                                        <input 
                                            type="password" 
                                            name="confirmPassword"
                                            value={formData.confirmPassword}
                                            onChange={handleChange}
                                            placeholder="••••••••"
                                            autoComplete="new-password"
                                        />
                                        <Lock size={18} />
                                    </div>
                                </div>
                            </div>
                        </div>

                        <button type="submit" className="save-btn" disabled={isSubmitting}>
                            {isSubmitting ? 'Saving...' : (
                                <>
                                    <Save size={18} />
                                    <span>Update Profile</span>
                                </>
                            )}
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
};

export default ProfilePage;
