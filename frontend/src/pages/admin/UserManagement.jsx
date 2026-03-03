import React, { useState, useEffect, useRef, useCallback } from 'react';
import { 
    Search, UserPlus, Trash2, Database, AlertCircle, CheckCircle, RefreshCw,
    User, Shield, Smartphone, Monitor, Globe, Lock, Mail, Phone, UserCheck, 
    Briefcase, X, Filter, Clock
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import '../../css/Dashboard.css';

const UserManagement = () => {
    const { user } = useAuth();
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState("");
    const [dbConnected, setDbConnected] = useState(false);
    const [showAddForm, setShowAddForm] = useState(false);
    const [newUser, setNewUser] = useState({ name: '', username: '', email: '', password: '', phone: '', role: 'farmer', access: 'both', googleEmail: '' });
    const [message, setMessage] = useState(null);
    const [refreshing, setRefreshing] = useState(false);
    const [lastUpdated, setLastUpdated] = useState(null);
    const [countdown, setCountdown] = useState(30);
    const countdownRef = useRef(null);
    const AUTO_REFRESH_SEC = 30;

    // Filters
    const [sortOrder, setSortOrder] = useState('newest'); // newest, oldest
    const [dateRange, setDateRange] = useState('all'); // all, 7days, 30days
    const [sourceFilter, setSourceFilter] = useState('all'); // all, web, iteagrow, both

    const fetchUsers = useCallback(async ({ silent = false } = {}) => {
        if (!silent) setLoading(true);
        else setRefreshing(true);
        try {
            const response = await fetch('/api/users', {
                headers: { 'Authorization': `Bearer ${user.token}` }
            });
            const data = await response.json();
            if (response.ok) {
                setUsers(data);
                setDbConnected(true);
                setLastUpdated(new Date());
            } else {
                setDbConnected(false);
            }
        } catch (error) {
            console.error('Error fetching users:', error);
            setDbConnected(false);
        } finally {
            setLoading(false);
            setRefreshing(false);
        }
    }, [user.token]);

    // Reset and restart the 30-second countdown
    const resetCountdown = useCallback(() => {
        setCountdown(AUTO_REFRESH_SEC);
        if (countdownRef.current) clearInterval(countdownRef.current);
        countdownRef.current = setInterval(() => {
            setCountdown(prev => {
                if (prev <= 1) {
                    fetchUsers({ silent: true });
                    return AUTO_REFRESH_SEC;
                }
                return prev - 1;
            });
        }, 1000);
    }, [fetchUsers]);

    useEffect(() => {
        fetchUsers();
        resetCountdown();
        return () => { if (countdownRef.current) clearInterval(countdownRef.current); };
    }, [user.token]);

    const [showDeleteModal, setShowDeleteModal] = useState(false);
    const [userToDelete, setUserToDelete] = useState(null);
    const [showDeleteMobileModal, setShowDeleteMobileModal] = useState(false);
    const [mobileUserToDelete, setMobileUserToDelete] = useState(null);

    const confirmDelete = (id) => {
        setUserToDelete(id);
        setShowDeleteModal(true);
    };

    const confirmDeleteMobile = (email) => {
        setMobileUserToDelete(email);
        setShowDeleteMobileModal(true);
    };

    const handleDelete = async () => {
        if (!userToDelete) return;

        try {
            const response = await fetch(`/api/users/${userToDelete}`, {
                method: 'DELETE',
                headers: {
                    'Authorization': `Bearer ${user.token}`
                }
            });
            if (response.ok) {
                setUsers(users.filter(u => u._id !== userToDelete));
                setMessage({ type: 'success', text: 'User deleted successfully' });
                setTimeout(() => setMessage(null), 3000);
            } else {
                setMessage({ type: 'error', text: 'Failed to delete user' });
            }
        } catch (error) {
            setMessage({ type: 'error', text: 'Error deleting user' });
        } finally {
            setShowDeleteModal(false);
            setUserToDelete(null);
        }
    };

    const handleDeleteMobile = async () => {
        if (!mobileUserToDelete) return;
        try {
            const response = await fetch(`/api/users/by-email/${encodeURIComponent(mobileUserToDelete)}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${user.token}` }
            });
            if (response.ok) {
                setUsers(users.filter(u => u.email !== mobileUserToDelete));
                setMessage({ type: 'success', text: 'Mobile user deleted successfully' });
                setTimeout(() => setMessage(null), 3000);
            } else {
                const data = await response.json().catch(() => ({}));
                setMessage({ type: 'error', text: data.message || 'Failed to delete mobile user' });
            }
        } catch (error) {
            setMessage({ type: 'error', text: 'Error deleting mobile user' });
        } finally {
            setShowDeleteMobileModal(false);
            setMobileUserToDelete(null);
        }
    };

    const handleCreate = async (e) => {
        e.preventDefault();
        try {
            const response = await fetch('/api/users', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${user.token}`
                },
                body: JSON.stringify({
                    name: newUser.name,
                    username: newUser.username || undefined,
                    email: newUser.email,
                    password: newUser.password,
                    phone: newUser.phone,
                    role: newUser.role,
                    access: newUser.access,
                    googleEmail: newUser.googleEmail || undefined,
                })
            });
            const data = await response.json();
            if (response.ok) {
                await fetchUsers({ silent: true }); // Refresh to get merged source tags
                resetCountdown();
                setShowAddForm(false);
                setNewUser({ name: '', username: '', email: '', password: '', phone: '', role: 'farmer', access: 'both', googleEmail: '' });
                const atlasSuffix = data.atlasCreated === true
                    ? ' — Synced to Mobile DB ✓'
                    : data.atlasCreated === false
                        ? ' — Web DB only ⚠ (Mobile DB sync failed)'
                        : '';
                setMessage({ type: 'success', text: `User created successfully${atlasSuffix}` });
                setTimeout(() => setMessage(null), 5000);
            } else {
                setMessage({ type: 'error', text: data.message || 'Failed to create user' });
            }
        } catch (error) {
            setMessage({ type: 'error', text: 'Error creating user' });
        }
    };

    const getFilteredUsers = () => {
        let result = [...users];

        // Filter by Source
        if (sourceFilter !== 'all') {
            result = result.filter(u => (u.source || 'web') === sourceFilter);
        }

        // Filter by Date Range
        if (dateRange !== 'all') {
            const now = new Date();
            const days = dateRange === '7days' ? 7 : 30;
            const cutoffDate = new Date(now.setDate(now.getDate() - days));
            result = result.filter(u => new Date(u.createdAt) >= cutoffDate);
        }

        // Filter by Search
        if (searchTerm) {
            const lowerterm = searchTerm.toLowerCase();
            result = result.filter(u => 
                u.name.toLowerCase().includes(lowerterm) ||
                u.email.toLowerCase().includes(lowerterm)
            );
        }

        // Sort
        result.sort((a, b) => { // Sort by Joined Date (createdAt)
             const dA = new Date(a.createdAt || 0);
             const dB = new Date(b.createdAt || 0);
             return sortOrder === 'newest' ? dB - dA : dA - dB;
        });

        return result;
    };

                    const filteredUsers = getFilteredUsers();

    const formatDate = (dateString) => {
        if (!dateString) return 'Never';
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', { 
            month: 'short', 
            day: 'numeric', 
            year: 'numeric' 
        }) + ' ' + date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    };

    const SourceBadge = ({ source }) => {
        const map = {
            'web':      { label: 'WEB',   color: '#3498db', bg: 'rgba(52,152,219,0.1)', icon: <Monitor size={12} /> },
            'iteagrow': { label: 'MOBILE', color: '#e67e22', bg: 'rgba(230,126,34,0.1)', icon: <Smartphone size={12} /> },
            'both':     { label: 'BOTH',   color: '#2ecc71', bg: 'rgba(46,204,113,0.1)', icon: <Globe size={12} /> },
        };
        const s = map[source] || map['web'];
        return (
            <span style={{
                background: s.bg,
                color: s.color,
                border: `1px solid ${s.color}44`,
                borderRadius: '6px',
                padding: '4px 8px',
                fontSize: '0.7rem',
                fontWeight: '700',
                letterSpacing: '0.04em',
                lineHeight: 1,
                display: 'inline-flex',
                alignItems: 'center',
                gap: '5px'
            }}>
                {s.icon}
                {s.label}
            </span>
        );
    };

    return (
        <div className="dashboard-container">
            <style>{`@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }`}</style>
            <header className="dashboard-header" style={{ marginBottom: '30px' }}>
                <div>
                    <h1 style={{ fontSize: '2.5rem', background: 'linear-gradient(90deg, #fff, #aaa)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', fontWeight: '800' }}>User Management</h1>
                    <p className="dashboard-subtitle" style={{ fontSize: '1.1rem', color: '#fff', opacity: 0.8 }}>Admin tool for estate access control and user coordination</p>
                    {lastUpdated && (
                        <p style={{ fontSize: '0.75rem', color: '#fff', opacity: 0.4, marginTop: '4px', display: 'flex', alignItems: 'center', gap: '4px' }}>
                            <RefreshCw size={10} />
                            Last sync: {lastUpdated.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
                        </p>
                    )}
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: '12px' }}>
                    {/* Action Buttons */}
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                        {/* DB Status */}
                        <div style={{ 
                            background: dbConnected ? 'rgba(46, 204, 113, 0.15)' : 'rgba(231, 76, 60, 0.15)',
                            border: `1px solid ${dbConnected ? 'rgba(46, 204, 113, 0.3)' : 'rgba(231, 76, 60, 0.3)'}`,
                            padding: '10px',
                            borderRadius: '10px',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            transition: 'all 0.3s ease'
                        }}
                        title={dbConnected ? 'Database Connected' : 'Database Offline'}
                        >
                            <Database size={20} color={dbConnected ? '#2ecc71' : '#e74c3c'} />
                        </div>

                        {/* Manual Refresh + countdown */}
                        <button
                            onClick={() => { fetchUsers({ silent: true }); resetCountdown(); }}
                            disabled={refreshing}
                            title={`Refresh now (auto in ${countdown}s)`}
                            style={{
                                background: 'rgba(52,152,219,0.15)',
                                border: '1px solid rgba(52,152,219,0.35)',
                                color: '#3498db',
                                padding: '10px 12px',
                                borderRadius: '10px',
                                cursor: refreshing ? 'not-allowed' : 'pointer',
                                display: 'flex',
                                alignItems: 'center',
                                gap: '7px',
                                fontSize: '0.78rem',
                                fontWeight: 600,
                                opacity: refreshing ? 0.6 : 1,
                                transition: 'all 0.2s ease',
                            }}
                        >
                            <RefreshCw
                                size={16}
                                style={{ animation: refreshing ? 'spin 0.7s linear infinite' : 'none' }}
                            />
                            <span>{refreshing ? 'Refreshing…' : `${countdown}s`}</span>
                        </button>

                        {/* Add User Button - Icon Only */}
                        <button 
                            onClick={() => setShowAddForm(!showAddForm)}
                            style={{ 
                                background: showAddForm ? 'rgba(231, 76, 60, 0.2)' : 'rgba(46, 204, 113, 0.2)',
                                border: `1px solid ${showAddForm ? 'rgba(231, 76, 60, 0.4)' : 'rgba(46, 204, 113, 0.4)'}`,
                                color: showAddForm ? '#e74c3c' : '#2ecc71',
                                padding: '10px',
                                borderRadius: '10px',
                                cursor: 'pointer',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                transition: 'all 0.3s ease'
                            }}
                            title={showAddForm ? 'Cancel' : 'Add User'}
                            onMouseEnter={(e) => {
                                e.currentTarget.style.background = showAddForm ? 'rgba(231, 76, 60, 0.3)' : 'rgba(46, 204, 113, 0.3)';
                                e.currentTarget.style.transform = 'translateY(-2px)';
                                e.currentTarget.style.boxShadow = showAddForm ? '0 4px 12px rgba(231, 76, 60, 0.3)' : '0 4px 12px rgba(46, 204, 113, 0.3)';
                            }}
                            onMouseLeave={(e) => {
                                e.currentTarget.style.background = showAddForm ? 'rgba(231, 76, 60, 0.2)' : 'rgba(46, 204, 113, 0.2)';
                                e.currentTarget.style.transform = 'translateY(0)';
                                e.currentTarget.style.boxShadow = 'none';
                            }}
                        >
                            <UserPlus size={20} />
                        </button>
                    </div>

                    {/* Status Text */}
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <span style={{ color: dbConnected ? '#2ecc71' : '#e74c3c', fontSize: '0.85rem', fontWeight: '500' }}>
                            {dbConnected ? 'Database Connected' : 'Database Offline'}
                        </span>
                    </div>
                </div>
            </header>

            {message && (
                <div style={{ 
                    padding: '16px 20px', 
                    marginBottom: '25px', 
                    borderRadius: '12px', 
                    background: message.type === 'success' ? 'rgba(46, 204, 113, 0.15)' : 'rgba(239, 68, 68, 0.15)',
                    color: '#fff',
                    border: `1px solid ${message.type === 'success' ? 'rgba(46, 204, 113, 0.4)' : 'rgba(239, 68, 68, 0.4)'}`,
                    display: 'flex',
                    alignItems: 'center',
                    gap: '12px',
                    boxShadow: message.type === 'success' ? '0 4px 15px rgba(46, 204, 113, 0.1)' : '0 4px 15px rgba(239, 68, 68, 0.1)',
                    backdropFilter: 'blur(10px)',
                    animation: 'slideDown 0.4s cubic-bezier(0.4, 0, 0.2, 1)'
                }}>
                    {message.type === 'success' ? 
                        <CheckCircle size={20} style={{ color: '#2ecc71' }} /> : 
                        <AlertCircle size={20} style={{ color: '#ef4444' }} />
                    }
                    <span style={{ fontWeight: '600', fontSize: '0.95rem', letterSpacing: '0.01em' }}>{message.text}</span>
                </div>
            )}

            {/* Source Stats Bar */}
            {!loading && users.length > 0 && (
                <div style={{ display: 'flex', gap: '12px', marginBottom: '25px', flexWrap: 'wrap' }}>
                    {[
                        { label: 'All Users', value: 'all', count: users.length, color: '#3498db', accent: '#3498db', bg: 'rgba(52,152,219,0.25)', icon: <UserCheck size={16} /> },
                        { label: 'Web Users', value: 'web', count: users.filter(u => (u.source || 'web') === 'web').length, color: '#fff', accent: '#3498db', bg: 'rgba(52,152,219,0.2)', icon: <Database size={16} /> },
                        { label: 'Mobile Users', value: 'iteagrow', count: users.filter(u => u.source === 'iteagrow').length, color: '#e67e22', accent: '#e67e22', bg: 'rgba(230,126,34,0.25)', icon: <Smartphone size={16} /> },
                        { label: 'Dual Access', value: 'both', count: users.filter(u => u.source === 'both').length, color: '#2ecc71', accent: '#2ecc71', bg: 'rgba(46,204,113,0.25)', icon: <Globe size={16} /> },
                    ].map(s => (
                        <button
                            key={s.value}
                            onClick={() => setSourceFilter(s.value)}
                            style={{
                                background: sourceFilter === s.value ? s.bg : 'rgba(255,255,255,0.02)',
                                border: `1px solid ${sourceFilter === s.value ? s.color + '66' : 'rgba(255,255,255,0.08)'}`,
                                borderRadius: '12px',
                                padding: '10px 18px',
                                cursor: 'pointer',
                                display: 'flex',
                                alignItems: 'center',
                                gap: '10px',
                                color: '#fff',
                                opacity: sourceFilter === s.value ? 1 : 0.85,
                                fontSize: '0.88rem',
                                fontWeight: '800',
                                transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                                boxShadow: sourceFilter === s.value ? `0 4px 15px ${s.accent}44` : 'none',
                                letterSpacing: '0.01em'
                            }}
                        >
                            <span style={{ color: sourceFilter === s.value ? s.accent : '#fff', opacity: sourceFilter === s.value ? 1 : 0.7 }}>{s.icon}</span>
                            {s.label}
                            <span style={{
                                background: sourceFilter === s.value ? '#fff' : 'rgba(255,255,255,0.2)',
                                color: sourceFilter === s.value ? s.accent : '#fff',
                                borderRadius: '8px',
                                padding: '2px 10px',
                                fontSize: '0.8rem',
                                fontWeight: '900',
                                boxShadow: sourceFilter === s.value ? '0 2px 8px rgba(0,0,0,0.3)' : 'none'
                            }}>{s.count}</span>
                        </button>
                    ))}
                </div>
            )}

            {/* Add User Form */}
            {showAddForm && (
                <div className="form-card">
                    <h3 className="form-title">Add New User</h3>

                    {/* ── Role Type Selector ── */}
                    <div style={{ display: 'flex', gap: '12px', marginBottom: '24px' }}>
                        {[
                            { value: 'farmer',  label: 'Farmer / Normal User', icon: <User size={24} />, desc: 'Field worker or regular app user',  accent: '#27ae60', accentBg: 'rgba(39,174,96,0.1)',   textColor: '#82e0aa' },
                            { value: 'manager', label: 'Manager',              icon: <Shield size={24} />, desc: 'Supervisor with elevated access',   accent: '#9b59b6', accentBg: 'rgba(155,89,182,0.1)', textColor: '#c39bd3' },
                        ].map(r => (
                            <button
                                key={r.value}
                                type="button"
                                onClick={() => setNewUser({ ...newUser, role: r.value, googleEmail: '' })}
                                style={{
                                    flex: 1,
                                    padding: '16px 16px',
                                    borderRadius: '12px',
                                    border: `1px solid ${newUser.role === r.value ? r.accent : 'rgba(255,255,255,0.1)'}`,
                                    background: newUser.role === r.value ? r.accentBg : 'rgba(255,255,255,0.02)',
                                    color: newUser.role === r.value ? '#fff' : '#888',
                                    cursor: 'pointer',
                                    textAlign: 'left',
                                    transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                                    boxShadow: newUser.role === r.value ? `0 4px 20px ${r.accent}22` : 'none',
                                    position: 'relative',
                                    overflow: 'hidden'
                                }}
                            >
                                <div style={{ 
                                    color: newUser.role === r.value ? r.accent : '#555', 
                                    marginBottom: '10px' 
                                }}>{r.icon}</div>
                                <div style={{ fontWeight: '700', fontSize: '0.95rem', color: newUser.role === r.value ? '#fff' : '#888' }}>{r.label}</div>
                                <div style={{ fontSize: '0.78rem', opacity: 0.6, marginTop: '2px' }}>{r.desc}</div>
                                {newUser.role === r.value && (
                                    <div style={{
                                        position: 'absolute',
                                        right: '12px',
                                        top: '12px'
                                    }}>
                                        <CheckCircle size={16} color={r.accent} />
                                    </div>
                                )}
                            </button>
                        ))}
                    </div>

                    <form onSubmit={handleCreate} autoComplete="off">
                        {/* ── Standard Fields ── */}
                        <div className="form-grid">
                            <div className="form-group">
                                <label>Full Name</label>
                                <input
                                    type="text"
                                    required
                                    className="form-input"
                                    value={newUser.name}
                                    onChange={e => setNewUser({ ...newUser, name: e.target.value })}
                                    placeholder="Full Name"
                                    autoComplete="off"
                                />
                            </div>
                            <div className="form-group">
                                <label>
                                    Username
                                    <span style={{ color: '#888', fontWeight: 400, fontSize: '0.78rem', marginLeft: '6px' }}>(used to login on mobile)</span>
                                </label>
                                <input
                                    type="text"
                                    required
                                    className="form-input"
                                    value={newUser.username}
                                    onChange={e => setNewUser({ ...newUser, username: e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, '') })}
                                    placeholder="e.g. Gayan_farmer"
                                    autoComplete="off"
                                />
                            </div>
                            <div className="form-group">
                                <label>Email</label>
                                <input
                                    type="email"
                                    required
                                    className="form-input"
                                    value={newUser.email}
                                    onChange={e => setNewUser({ ...newUser, email: e.target.value })}
                                    placeholder="email@example.com"
                                    autoComplete="new-email"
                                />
                            </div>
                            <div className="form-group">
                                <label>Password</label>
                                <input
                                    type="password"
                                    required
                                    className="form-input"
                                    value={newUser.password}
                                    onChange={e => setNewUser({ ...newUser, password: e.target.value })}
                                    placeholder="••••••••"
                                    autoComplete="new-password"
                                />
                            </div>
                            <div className="form-group">
                                <label>Phone</label>
                                <input
                                    type="text"
                                    required
                                    className="form-input"
                                    value={newUser.phone}
                                    onChange={e => {
                                        const value = e.target.value.replace(/[^0-9+]/g, '');
                                        setNewUser({ ...newUser, phone: value });
                                    }}
                                    placeholder="+94 77 123 4567"
                                    autoComplete="off"
                                />
                            </div>
                        </div>

                        {/* ── App Access ── */}
                        <div style={{ marginBottom: '25px' }}>
                            <label style={{ display: 'block', color: '#fff', fontSize: '0.9rem', marginBottom: '12px', fontWeight: '600', opacity: 0.9 }}>
                                App Access Controls
                            </label>
                            <div style={{ display: 'flex', gap: '12px' }}>
                                {[
                                    { value: 'mobile', label: 'Mobile Only', icon: <Smartphone size={18} /> },
                                    { value: 'web',    label: 'Web Only',    icon: <Monitor size={18} /> },
                                    { value: 'both',   label: 'Both Platforms', icon: <Globe size={18} /> },
                                ].map(a => (
                                    <button
                                        key={a.value}
                                        type="button"
                                        onClick={() => setNewUser({ ...newUser, access: a.value })}
                                        style={{
                                            flex: 1,
                                            padding: '12px 10px',
                                            borderRadius: '10px',
                                            border: `1px solid ${newUser.access === a.value ? '#3498db' : 'rgba(255,255,255,0.08)'}`,
                                            background: newUser.access === a.value ? 'rgba(52,152,219,0.15)' : 'rgba(255,255,255,0.02)',
                                            color: newUser.access === a.value ? '#fff' : '#666',
                                            cursor: 'pointer',
                                            fontSize: '0.85rem',
                                            fontWeight: '600',
                                            transition: 'all 0.3s ease',
                                            display: 'flex',
                                            flexDirection: 'column',
                                            alignItems: 'center',
                                            gap: '6px'
                                        }}
                                    >
                                        <div style={{ color: newUser.access === a.value ? '#3498db' : '#444' }}>{a.icon}</div>
                                        <span>{a.label}</span>
                                    </button>
                                ))}
                            </div>
                        </div>

                        {/* ── Google Gmail (all roles) ── */}
                        <div className="form-group" style={{ marginBottom: '20px' }}>
                            <label style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                <span style={{ color: '#e74c3c', fontWeight: 700, fontSize: '1rem' }}>G</span>
                                Google Sign-In Gmail
                                <span style={{ color: '#888', fontWeight: 400, fontSize: '0.78rem' }}>(optional — for mobile Google login)</span>
                            </label>
                            <input
                                type="email"
                                className="form-input"
                                value={newUser.googleEmail}
                                onChange={e => setNewUser({ ...newUser, googleEmail: e.target.value })}
                                placeholder={newUser.role === 'manager' ? 'manager@gmail.com' : 'farmer@gmail.com'}
                                autoComplete="off"
                            />
                            <small style={{ color: '#777', fontSize: '0.78rem', marginTop: '5px', display: 'block' }}>
                                User can sign into the mobile app using this Gmail via Google Auth.
                            </small>
                        </div>

                        <div className="form-actions">
                            <button type="button" className="btn btn-secondary" onClick={() => setShowAddForm(false)}>Cancel</button>
                            <button type="submit" className="btn btn-primary">
                                Create {newUser.role === 'manager' ? 'Manager' : 'Farmer'}
                            </button>
                        </div>
                    </form>
                </div>
            )}

            {/* Controls */}
            <div className="dashboard-card" style={{ 
                marginBottom: '20px', 
                padding: '20px',
                display: 'flex', 
                alignItems: 'center', 
                justifyContent: 'space-between', 
                gap: '20px',
                flexWrap: 'wrap' 
            }}>
                <div style={{ position: 'relative', flex: '1 1 300px', maxWidth: '400px' }}>
                    <Search size={18} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#fff', opacity: 0.4 }} />
                    <input 
                        type="text" 
                        placeholder="Search users..." 
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        style={{ 
                            width: '100%', 
                            padding: '12px 12px 12px 40px', 
                            borderRadius: '10px', 
                            border: '1px solid rgba(255,255,255,0.1)', 
                            background: 'rgba(255,255,255,0.05)',
                            color: 'white',
                            outline: 'none',
                            fontSize: '0.9rem',
                            transition: 'all 0.3s ease'
                        }}
                        onFocus={(e) => {
                            e.target.style.background = 'rgba(255,255,255,0.08)';
                            e.target.style.borderColor = 'rgba(255,255,255,0.2)';
                        }}
                        onBlur={(e) => {
                            e.target.style.background = 'rgba(255,255,255,0.05)';
                            e.target.style.borderColor = 'rgba(255,255,255,0.1)';
                        }}
                    />
                </div>

                <div style={{ display: 'flex', gap: '15px', flexWrap: 'wrap' }}>
                    {/* Date Range Filter */}
                    <div className="custom-select-wrapper" style={{ position: 'relative', minWidth: '150px' }}>
                        <div style={{ 
                            position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', 
                            color: '#fff', opacity: 0.4, pointerEvents: 'none', display: 'flex' 
                        }}>
                            <Filter size={14} />
                        </div>
                        <select 
                            value={dateRange} 
                            onChange={(e) => setDateRange(e.target.value)}
                            className="form-input"
                            style={{ 
                                padding: '10px 30px 10px 34px', 
                                fontSize: '0.85rem', 
                                borderRadius: '10px',
                                background: 'rgba(255,255,255,0.05)',
                                borderColor: 'rgba(255,255,255,0.1)',
                                cursor: 'pointer',
                                appearance: 'none',
                                color: 'white',
                                width: '100%',
                                fontWeight: '600'
                            }}
                        >
                            <option value="all">All Time</option>
                            <option value="7days">Last 7 Days</option>
                            <option value="30days">Last 30 Days</option>
                        </select>
                        <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" style={{ position: 'absolute', right: '12px', top: '50%', transform: 'translateY(-50%)', pointerEvents: 'none', color: '#fff', opacity: 0.3 }}><polyline points="6 9 12 15 18 9"></polyline></svg>
                    </div>

                    {/* Sort Order */}
                    <div className="custom-select-wrapper" style={{ position: 'relative', minWidth: '150px' }}>
                        <select 
                            value={sortOrder} 
                            onChange={(e) => setSortOrder(e.target.value)}
                            className="form-input"
                            style={{ 
                                padding: '10px 30px 10px 12px', 
                                fontSize: '0.85rem', 
                                borderRadius: '10px',
                                background: 'rgba(255,255,255,0.05)',
                                borderColor: 'rgba(255,255,255,0.1)',
                                cursor: 'pointer',
                                appearance: 'none',
                                color: 'white',
                                width: '100%',
                                fontWeight: '600'
                            }}
                        >
                            <option value="newest">Newest First</option>
                            <option value="oldest">Oldest First</option>
                        </select>
                         <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" style={{ position: 'absolute', right: '12px', top: '50%', transform: 'translateY(-50%)', pointerEvents: 'none', color: '#fff', opacity: 0.3 }}><polyline points="6 9 12 15 18 9"></polyline></svg>
                    </div>
                </div>
            </div>
            
            <style>{`
                /* Ensure dropdown options are visible in dark mode */
                select option {
                    background-color: #2c3e50;
                    color: white;
                }
            `}</style>

            {/* Users Table */}
            <div className="dashboard-card" style={{ padding: '0', overflow: 'hidden' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left', tableLayout: 'fixed' }}>
                    <thead>
                        <tr style={{ background: 'rgba(255,255,255,0.02)' }}>
                            <th style={{ padding: '18px 25px', color: '#fff', fontWeight: '700', fontSize: '0.75rem', textTransform: 'uppercase', opacity: 0.6, letterSpacing: '0.05em', width: '25%' }}>User Identity</th>
                            <th style={{ padding: '18px 25px', color: '#fff', fontWeight: '700', fontSize: '0.75rem', textTransform: 'uppercase', opacity: 0.6, letterSpacing: '0.05em', width: '22%' }}>Access Email</th>
                            <th style={{ padding: '18px 25px', color: '#fff', fontWeight: '700', fontSize: '0.75rem', textTransform: 'uppercase', opacity: 0.6, letterSpacing: '0.05em', width: '12%' }}>DataSource</th>
                            <th style={{ padding: '18px 25px', color: '#fff', fontWeight: '700', fontSize: '0.75rem', textTransform: 'uppercase', opacity: 0.6, letterSpacing: '0.05em', width: '14%' }}>Network</th>
                            <th style={{ padding: '18px 25px', color: '#fff', fontWeight: '700', fontSize: '0.75rem', textTransform: 'uppercase', opacity: 0.6, letterSpacing: '0.05em', width: '18%' }}>Last Active</th>
                            <th style={{ padding: '18px 25px', color: '#fff', fontWeight: '700', fontSize: '0.75rem', textTransform: 'uppercase', opacity: 0.6, letterSpacing: '0.05em', textAlign: 'right', width: '9%' }}>Manage</th>
                        </tr>
                    </thead>
                    <tbody>
                        {loading ? (
                            <tr><td colSpan="6" style={{ padding: '40px', textAlign: 'center', color: '#fff', opacity: 0.5 }}>Loading estate users...</td></tr>
                        ) : filteredUsers.length === 0 ? (
                            <tr><td colSpan="6" style={{ padding: '40px', textAlign: 'center', color: '#fff', opacity: 0.5 }}>No users found in current filter.</td></tr>
                        ) : (
                            filteredUsers.map(u => (
                                <tr key={u._id} style={{ borderBottom: '1px solid rgba(255,255,255,0.03)', transition: 'all 0.3s ease' }} className="table-row">
                                    <td style={{ padding: '20px 25px' }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '15px' }}>
                                            <div style={{ 
                                                width: '40px', height: '40px', borderRadius: '12px', 
                                                background: 'linear-gradient(135deg, rgba(255,255,255,0.1), rgba(255,255,255,0.02))', 
                                                display: 'flex', alignItems: 'center', justifyContent: 'center', 
                                                color: '#fff', fontWeight: '800', fontSize: '0.9rem',
                                                border: '1px solid rgba(255,255,255,0.1)',
                                                boxShadow: '0 4px 10px rgba(0,0,0,0.2)'
                                            }}>
                                                {(u.name || '?').charAt(0).toUpperCase()}
                                            </div>
                                            <div>
                                                <div style={{ color: '#fff', fontWeight: '700', fontSize: '0.95rem' }}>{u.name || 'Anonymous User'}</div>
                                                <div style={{ color: '#fff', opacity: 0.4, fontSize: '0.75rem', marginTop: '2px', textTransform: 'uppercase', fontWeight: '800', letterSpacing: '0.02em' }}>
                                                    {u.role || 'Farmer'}
                                                </div>
                                            </div>
                                        </div>
                                    </td>
                                    <td style={{ padding: '20px 25px' }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', color: '#fff', opacity: 0.7, fontSize: '0.9rem', overflow: 'hidden' }}>
                                            <Mail size={14} style={{ flexShrink: 0, opacity: 0.5 }} />
                                            <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{u.email}</span>
                                        </div>
                                    </td>
                                    <td style={{ padding: '20px 25px' }}>
                                        <SourceBadge source={u.source || 'web'} />
                                    </td>
                                    <td style={{ padding: '20px 25px' }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                            <div style={{ 
                                                width: '8px', height: '8px', borderRadius: '50%', 
                                                background: '#10b981',
                                                boxShadow: '0 0 10px #10b981'
                                            }}></div>
                                            <span style={{ color: '#fff', fontWeight: '600', fontSize: '0.85rem' }}>Secure Sync</span>
                                        </div>
                                    </td>
                                    <td style={{ padding: '20px 25px', color: '#fff', opacity: 0.6, fontSize: '0.85rem', fontWeight: '500' }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                            <Clock size={14} opacity={0.5} />
                                            {u.lastLogin
                                                ? formatDate(u.lastLogin)
                                                : <span style={{ opacity: 0.4, fontStyle: 'italic' }}>Never</span>
                                            }
                                        </div>
                                    </td>
                                    <td style={{ padding: '20px 25px', textAlign: 'right' }}>
                                        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px' }}>
                                            {user._id !== u._id && (
                                                <button
                                                    onClick={() => u.source === 'iteagrow' ? confirmDeleteMobile(u.email) : confirmDelete(u._id)}
                                                    style={{ background: 'rgba(239, 68, 68, 0.1)', border: '1px solid rgba(239, 68, 68, 0.2)', color: '#ef4444', padding: '8px', borderRadius: '8px', cursor: 'pointer', transition: 'all 0.2s' }}
                                                    onMouseEnter={(e) => { e.currentTarget.style.background = 'rgba(239, 68, 68, 0.2)'; e.currentTarget.style.borderColor = 'rgba(239, 68, 68, 0.4)'; }}
                                                    onMouseLeave={(e) => { e.currentTarget.style.background = 'rgba(239, 68, 68, 0.1)'; e.currentTarget.style.borderColor = 'rgba(239, 68, 68, 0.2)'; }}
                                                    title="Remove Access"
                                                >
                                                    <Trash2 size={16} />
                                                </button>
                                            )}
                                        </div>
                                    </td>
                                </tr>
                            ))
                        )}
                    </tbody>
                </table>
            </div>

            {/* Custom Delete Confirmation Modal */}
            {showDeleteModal && (
                <div className="modal-overlay" onClick={() => setShowDeleteModal(false)}>
                    <div className="modal-content" onClick={e => e.stopPropagation()}>
                        <div className="modal-header">
                            <h3 className="modal-title">Confirm Deletion</h3>
                        </div>
                        <div className="modal-body">
                            <p>Are you sure you want to delete this user? This action cannot be undone.</p>
                        </div>
                        <div className="modal-actions">
                            <button className="btn btn-secondary" onClick={() => setShowDeleteModal(false)}>Cancel</button>
                            <button className="btn btn-danger" onClick={handleDelete}>Delete User</button>
                        </div>
                    </div>
                </div>
            )}

            {/* Mobile User Delete Confirmation Modal */}
            {showDeleteMobileModal && (
                <div className="modal-overlay" onClick={() => setShowDeleteMobileModal(false)}>
                    <div className="modal-content" onClick={e => e.stopPropagation()}>
                        <div className="modal-header">
                            <h3 className="modal-title">Delete Mobile User</h3>
                        </div>
                        <div className="modal-body">
                            <p>Delete <strong>{mobileUserToDelete}</strong> from the Mobile DB?</p>
                            <p style={{ color: '#aaa', fontSize: '0.85rem' }}>This user was created via the mobile app and only exists in the Mobile DB. This action cannot be undone.</p>
                        </div>
                        <div className="modal-actions">
                            <button className="btn btn-secondary" onClick={() => setShowDeleteMobileModal(false)}>Cancel</button>
                            <button className="btn btn-danger" onClick={handleDeleteMobile}>Delete</button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default UserManagement;
