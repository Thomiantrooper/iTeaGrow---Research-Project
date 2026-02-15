import React, { useState, useEffect } from 'react';
import { Search, UserPlus, Trash2, Database, AlertCircle, CheckCircle } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import '../../css/Dashboard.css';

const UserManagement = () => {
    const { user } = useAuth();
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState("");
    const [dbConnected, setDbConnected] = useState(false);
    const [showAddForm, setShowAddForm] = useState(false);
    const [newUser, setNewUser] = useState({ name: '', email: '', password: '', phone: '', role: 'farmer' });
    const [message, setMessage] = useState(null);

    // Filters
    const [sortOrder, setSortOrder] = useState('newest'); // newest, oldest
    const [dateRange, setDateRange] = useState('all'); // all, 7days, 30days

    const fetchUsers = async () => {
        try {
            const response = await fetch('/api/users', {
                headers: {
                    'Authorization': `Bearer ${user.token}`
                }
            });
            const data = await response.json();
            if (response.ok) {
                setUsers(data);
                setDbConnected(true);
            } else {
                setDbConnected(false);
                console.error("Failed to fetch users");
            }
        } catch (error) {
            console.error("Error fetching users:", error);
            setDbConnected(false);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchUsers();
    }, [user.token]);

    const [showDeleteModal, setShowDeleteModal] = useState(false);
    const [userToDelete, setUserToDelete] = useState(null);

    const confirmDelete = (id) => {
        setUserToDelete(id);
        setShowDeleteModal(true);
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

    const handleCreate = async (e) => {
        e.preventDefault();
        try {
            const response = await fetch('/api/users', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${user.token}`
                },
                body: JSON.stringify(newUser)
            });
            const data = await response.json();
            if (response.ok) {
                setUsers([...users, data]);
                setShowAddForm(false);
                setNewUser({ name: '', email: '', password: '', phone: '', role: 'farmer' });
                setMessage({ type: 'success', text: 'User created successfully' });
                setTimeout(() => setMessage(null), 3000);
            } else {
                setMessage({ type: 'error', text: data.message || 'Failed to create user' });
            }
        } catch (error) {
            setMessage({ type: 'error', text: 'Error creating user' });
        }
    };

    const getFilteredUsers = () => {
        let result = [...users];

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
        return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    };

    return (
        <div className="dashboard-container">
            <header className="dashboard-header" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                    <h1>User Management</h1>
                    <p className="dashboard-subtitle">Manage users and access.</p>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
                     {/* DB Connectivity Indicator */}
                    <div style={{ 
                        display: 'flex', 
                        alignItems: 'center', 
                        gap: '8px', 
                        background: 'rgba(255,255,255,0.1)', 
                        padding: '8px 12px', 
                        borderRadius: '20px',
                        border: `1px solid ${dbConnected ? '#2ecc71' : '#e74c3c'}`
                    }}>
                        <Database size={16} color={dbConnected ? '#2ecc71' : '#e74c3c'} />
                        <span style={{ fontSize: '0.85rem', color: dbConnected ? '#2ecc71' : '#e74c3c', fontWeight: '600' }}>
                            {dbConnected ? 'DB Connected' : 'DB Offline'}
                        </span>
                    </div>

                    <button className="btn btn-primary" onClick={() => setShowAddForm(!showAddForm)} style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <UserPlus size={18} /> {showAddForm ? 'Cancel' : 'Add User'}
                    </button>
                </div>
            </header>

            {message && (
                <div style={{ 
                    padding: '10px 20px', 
                    marginBottom: '20px', 
                    borderRadius: '8px', 
                    background: message.type === 'success' ? 'rgba(46, 204, 113, 0.2)' : 'rgba(231, 76, 60, 0.2)',
                    color: message.type === 'success' ? '#2ecc71' : '#e74c3c',
                    border: `1px solid ${message.type === 'success' ? '#2ecc71' : '#e74c3c'}`,
                    display: 'flex',
                    alignItems: 'center',
                    gap: '10px'
                }}>
                    {message.type === 'success' ? <CheckCircle size={18} /> : <AlertCircle size={18} />}
                    {message.text}
                </div>
            )}

            {/* Add User Form */}
            {showAddForm && (
                <div className="form-card">
                    <h3 className="form-title">Add New User</h3>
                    <form onSubmit={handleCreate} autoComplete="off">
                        <div className="form-grid">
                            <div className="form-group">
                                <label>Name</label>
                                <input 
                                    type="text" 
                                    required 
                                    className="form-input"
                                    value={newUser.name} 
                                    onChange={e => setNewUser({...newUser, name: e.target.value})}
                                    placeholder="Full Name"
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
                                    onChange={e => setNewUser({...newUser, email: e.target.value})}
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
                                    onChange={e => setNewUser({...newUser, password: e.target.value})}
                                    placeholder="********"
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
                                        setNewUser({...newUser, phone: value});
                                    }}
                                    placeholder="+94 77 123 4567"
                                    autoComplete="off" 
                                />
                            </div>
                        </div>
                        <div className="form-actions">
                            <button type="button" className="btn btn-secondary" onClick={() => setShowAddForm(false)}>Cancel</button>
                            <button type="submit" className="btn btn-primary">Create User</button>
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
                    <Search size={18} style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: '#ccc' }} />
                    <input 
                        type="text" 
                        placeholder="Search users..." 
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        style={{ 
                            width: '100%', 
                            padding: '10px 10px 10px 36px', 
                            borderRadius: '6px', 
                            border: '1px solid rgba(255,255,255,0.2)', 
                            background: 'rgba(255,255,255,0.1)',
                            color: 'white',
                            outline: 'none'
                        }}
                    />
                </div>

                <div style={{ display: 'flex', gap: '15px', flexWrap: 'wrap' }}>
                    {/* Date Range Filter */}
                    <div className="custom-select-wrapper" style={{ position: 'relative', minWidth: '150px' }}>
                        <select 
                            value={dateRange} 
                            onChange={(e) => setDateRange(e.target.value)}
                            className="form-input"
                            style={{ 
                                padding: '10px 30px 10px 12px', 
                                fontSize: '0.9rem', 
                                borderRadius: '6px',
                                background: 'rgba(255,255,255,0.05)',
                                borderColor: 'rgba(255,255,255,0.1)',
                                cursor: 'pointer',
                                appearance: 'none',
                                color: 'white',
                                width: '100%'
                            }}
                        >
                            <option value="all">All Time</option>
                            <option value="7days">Last 7 Days</option>
                            <option value="30days">Last 30 Days</option>
                        </select>
                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ position: 'absolute', right: '10px', top: '50%', transform: 'translateY(-50%)', pointerEvents: 'none', color: '#aaa' }}><polyline points="6 9 12 15 18 9"></polyline></svg>
                    </div>

                    {/* Sort Order */}
                    <div className="custom-select-wrapper" style={{ position: 'relative', minWidth: '150px' }}>
                        <select 
                            value={sortOrder} 
                            onChange={(e) => setSortOrder(e.target.value)}
                            className="form-input"
                            style={{ 
                                padding: '10px 30px 10px 12px', 
                                fontSize: '0.9rem', 
                                borderRadius: '6px',
                                background: 'rgba(255,255,255,0.05)',
                                borderColor: 'rgba(255,255,255,0.1)',
                                cursor: 'pointer',
                                appearance: 'none',
                                color: 'white',
                                width: '100%'
                            }}
                        >
                            <option value="newest">Newest First</option>
                            <option value="oldest">Oldest First</option>
                        </select>
                         <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ position: 'absolute', right: '10px', top: '50%', transform: 'translateY(-50%)', pointerEvents: 'none', color: '#aaa' }}><polyline points="6 9 12 15 18 9"></polyline></svg>
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
                <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                    <thead>
                        <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.1)', background: 'rgba(255,255,255,0.05)' }}>
                            <th style={{ padding: '16px 20px', color: '#ddd', fontWeight: '500', fontSize: '0.9rem' }}>User</th>
                            <th style={{ padding: '16px 20px', color: '#ddd', fontWeight: '500', fontSize: '0.9rem' }}>Email</th>
                            <th style={{ padding: '16px 20px', color: '#ddd', fontWeight: '500', fontSize: '0.9rem' }}>Status</th>
                            <th style={{ padding: '16px 20px', color: '#ddd', fontWeight: '500', fontSize: '0.9rem' }}>Last Active</th>
                            <th style={{ padding: '16px 20px', color: '#ddd', fontWeight: '500', fontSize: '0.9rem', textAlign: 'right' }}>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {loading ? (
                            <tr><td colSpan="5" style={{ padding: '20px', textAlign: 'center', color: '#ccc' }}>Loading users...</td></tr>
                        ) : filteredUsers.length === 0 ? (
                            <tr><td colSpan="5" style={{ padding: '20px', textAlign: 'center', color: '#ccc' }}>No users found.</td></tr>
                        ) : (
                            filteredUsers.map(u => (
                                <tr key={u._id} style={{ borderBottom: '1px solid rgba(255,255,255,0.05)', transition: 'background 0.2s' }} className="table-row">
                                    <td style={{ padding: '16px 20px' }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                            <div style={{ width: '36px', height: '36px', borderRadius: '50%', background: 'rgba(255,255,255,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#eee', fontWeight: '600' }}>
                                                {u.name.charAt(0).toUpperCase()}
                                            </div>
                                            <div style={{ color: 'white', fontWeight: '500' }}>{u.name}</div>
                                        </div>
                                    </td>
                                    <td style={{ padding: '16px 20px', color: '#ccc', fontSize: '0.9rem' }}>{u.email}</td>
                                    <td style={{ padding: '16px 20px' }}>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                            <div style={{ width: '6px', height: '6px', borderRadius: '50%', background: '#2ecc71' }}></div>
                                            <span style={{ color: '#eee' }}>Active</span>
                                        </div>
                                    </td>
                                    <td style={{ padding: '16px 20px', color: '#ccc', fontSize: '0.9rem' }}>
                                        {formatDate(u.updatedAt)}
                                    </td>
                                    <td style={{ padding: '16px 20px', textAlign: 'right' }}>
                                        {/* Prevent deleting yourself */}
                                        {user._id !== u._id && (
                                            <button 
                                                onClick={() => confirmDelete(u._id)}
                                                style={{ background: 'none', border: 'none', color: '#e74c3c', cursor: 'pointer', padding: '4px' }} 
                                                className="action-icon"
                                                title="Delete User"
                                            >
                                                <Trash2 size={16} />
                                            </button>
                                        )}
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
        </div>
    );
};

export default UserManagement;
