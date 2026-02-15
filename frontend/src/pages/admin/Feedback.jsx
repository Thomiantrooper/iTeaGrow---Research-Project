import React, { useState, useEffect } from 'react';
import { useAuth } from '../../context/AuthContext';
import { MessageSquare, Calendar, Mail, User } from 'lucide-react';
import '../../css/Dashboard.css'; // Reusing dashboard styles

const Feedback = () => {
    const [contacts, setContacts] = useState([]);
    const [filteredContacts, setFilteredContacts] = useState([]);
    const [loading, setLoading] = useState(true);
    const { user } = useAuth();
    
    // Filters and Search
    const [filter, setFilter] = useState('All'); // All, New, Replied
    const [searchTerm, setSearchTerm] = useState('');
    const [sortOrder, setSortOrder] = useState('newest'); // newest, oldest
    const [dateRange, setDateRange] = useState('all'); // all, 7days, 30days

    // Reply state
    const [replyingTo, setReplyingTo] = useState(null);
    const [replySubject, setReplySubject] = useState('');
    const [replyMessage, setReplyMessage] = useState('');
    const [sending, setSending] = useState(false);
    
    const [error, setError] = useState(null);
    const [successMsg, setSuccessMsg] = useState(null);

    useEffect(() => {
        const fetchContacts = async () => {
            try {
                const response = await fetch('/api/contact', {
                    headers: { 'Authorization': `Bearer ${user.token}` }
                });
                if (response.ok) {
                    const data = await response.json();
                    setContacts(data);
                    setFilteredContacts(data);
                } else {
                    setError('Failed to load feedback messages');
                }
            } catch (error) {
                console.error(error);
                setError('Network error while loading feedback');
            } finally {
                setLoading(false);
            }
        };

        if (user && user.token) {
            fetchContacts();
        }
    }, [user]);

    // Apply Filters
    useEffect(() => {
        let result = [...contacts];

        // Filter by Status
        if (filter !== 'All') {
            result = result.filter(c => c.status === filter);
        }

        // Filter by Date Range
        if (dateRange !== 'all') {
            const now = new Date();
            const days = dateRange === '7days' ? 7 : 30;
            const cutoffDate = new Date(now.setDate(now.getDate() - days));
            result = result.filter(c => new Date(c.createdAt) >= cutoffDate);
        }

        // Filter by Search
        if (searchTerm) {
            const lowerTerm = searchTerm.toLowerCase();
            result = result.filter(c => 
                c.name.toLowerCase().includes(lowerTerm) || 
                c.email.toLowerCase().includes(lowerTerm) || 
                c.message.toLowerCase().includes(lowerTerm)
            );
        }

        // Sort
        result.sort((a, b) => {
            const dateA = new Date(a.createdAt);
            const dateB = new Date(b.createdAt);
            return sortOrder === 'newest' ? dateB - dateA : dateA - dateB;
        });

        setFilteredContacts(result);
    }, [contacts, filter, searchTerm, sortOrder, dateRange]);

    const [replyFile, setReplyFile] = useState(null);

    const handleReplyClick = (contact) => {
        setReplyingTo(contact._id);
        setReplySubject(`Re: Inquiry from ${contact.name}`);
        setReplyMessage('');
        setReplyFile(null);
        setSuccessMsg(null);
        setError(null);
    };

    const handleCancelReply = () => {
        setReplyingTo(null);
        setReplySubject('');
        setReplyMessage('');
        setReplyFile(null);
    };

    const handleSendReply = async (contactId) => {
        if (!replySubject || !replyMessage) {
            setError("Subject and message are required.");
            return;
        }

        setSending(true);
        setError(null);

        try {
            const formData = new FormData();
            formData.append('subject', replySubject);
            formData.append('message', replyMessage);
            if (replyFile) {
                formData.append('file', replyFile);
            }

            const response = await fetch(`/api/contact/${contactId}/reply`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${user.token}`
                    // Content-Type is automatically set by browser for FormData
                },
                body: formData
            });

            if (response.ok) {
                setSuccessMsg("Reply sent successfully!");
                
                // Create new reply object for local state update
                const newReply = {
                    subject: replySubject,
                    message: replyMessage,
                    repliedAt: new Date().toISOString()
                };

                // Update local state to reflect 'Replied' status and add new reply immediately
                setContacts(prev => prev.map(c => 
                    c._id === contactId 
                        ? { 
                            ...c, 
                            status: 'Replied', 
                            replies: [...(c.replies || []), newReply] // Append new reply
                          } 
                        : c
                ));
                setTimeout(() => {
                    setSuccessMsg(null);
                    setReplyingTo(null);
                }, 2000);
            } else {
                const data = await response.json();
                setError(data.message || "Failed to send reply.");
            }
        } catch (err) {
            console.error(err);
            setError("Error sending reply.");
        } finally {
            setSending(false);
        }
    };

    const formatDate = (dateString) => {
        if (!dateString) return 'Just now';
        return new Date(dateString).toLocaleDateString(undefined, { month: 'short', day: 'numeric' }) + ' ' + new Date(dateString).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    };

    return (
        <div className="dashboard-container">
            <header className="dashboard-header">
                <div>
                    <h1>User Feedback</h1>
                    <p className="dashboard-subtitle">Manage user inquiries and support tickets.</p>
                </div>
                {/* Search Bar */}
                <div style={{ position: 'relative', width: '300px' }}>
                    <input 
                        type="text" 
                        placeholder="Search messages..." 
                        className="form-input"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        style={{ paddingLeft: '40px', background: 'rgba(255,255,255,0.2)', borderColor: 'transparent', color: 'white' }}
                    />
                    <div style={{ position: 'absolute', left: '12px', top: '50%', transform: 'translateY(-50%)', color: 'rgba(255,255,255,0.7)' }}>
                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                    </div>
                </div>
            </header>

            {/* Filter Tabs & Controls */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '25px', borderBottom: '1px solid rgba(255,255,255,0.1)', paddingBottom: '15px', flexWrap: 'wrap', gap: '15px' }}>
                <div style={{ display: 'flex', gap: '15px' }}>
                    {['All', 'New', 'Replied'].map(status => (
                        <button 
                            key={status}
                            onClick={() => setFilter(status)}
                            style={{
                                background: 'transparent',
                                border: 'none',
                                color: filter === status ? 'var(--tea-secondary)' : '#ccc',
                                fontWeight: filter === status ? '600' : '400',
                                cursor: 'pointer',
                                padding: '5px 10px',
                                borderBottom: filter === status ? '2px solid var(--tea-secondary)' : '2px solid transparent',
                                transition: 'all 0.3s ease'
                            }}
                        >
                            {status}
                        </button>
                    ))}
                </div>

                <div style={{ display: 'flex', gap: '15px' }}>
                    {/* Date Range Filter */}
                    <div className="custom-select-wrapper" style={{ position: 'relative' }}>
                        <select 
                            value={dateRange} 
                            onChange={(e) => setDateRange(e.target.value)}
                            className="form-input"
                            style={{ 
                                padding: '8px 30px 8px 12px', 
                                fontSize: '0.85rem', 
                                borderRadius: '6px',
                                background: 'rgba(255,255,255,0.05)',
                                borderColor: 'rgba(255,255,255,0.1)',
                                cursor: 'pointer',
                                appearance: 'none' 
                            }}
                        >
                            <option value="all">All Time</option>
                            <option value="7days">Last 7 Days</option>
                            <option value="30days">Last 30 Days</option>
                        </select>
                        <Calendar size={14} style={{ position: 'absolute', right: '10px', top: '50%', transform: 'translateY(-50%)', pointerEvents: 'none', color: '#aaa' }} />
                    </div>

                    {/* Sort Order */}
                    <div className="custom-select-wrapper" style={{ position: 'relative' }}>
                        <select 
                            value={sortOrder} 
                            onChange={(e) => setSortOrder(e.target.value)}
                            className="form-input"
                            style={{ 
                                padding: '8px 30px 8px 12px', 
                                fontSize: '0.85rem', 
                                borderRadius: '6px',
                                background: 'rgba(255,255,255,0.05)',
                                borderColor: 'rgba(255,255,255,0.1)',
                                cursor: 'pointer',
                                appearance: 'none'
                            }}
                        >
                            <option value="newest">Newest First</option>
                            <option value="oldest">Oldest First</option>
                        </select>
                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ position: 'absolute', right: '10px', top: '50%', transform: 'translateY(-50%)', pointerEvents: 'none', color: '#aaa' }}><line x1="12" y1="5" x2="12" y2="19"></line><polyline points="19 12 12 19 5 12"></polyline></svg>
                    </div>
                </div>
            </div>

            <div className="dashboard-card" style={{ padding: 0, overflow: 'hidden' }}>
                {loading ? (
                     <div style={{ padding: '60px', textAlign: 'center', color: '#ccc' }}>Loading messages...</div>
                ) : error && !replyingTo ? (
                    <div style={{ padding: '40px', textAlign: 'center', color: '#e74c3c' }}>{error}</div>
                ) : filteredContacts.length === 0 ? (
                    <div style={{ padding: '60px', textAlign: 'center', color: '#ccc', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '15px' }}>
                        <Mail size={40} style={{ opacity: 0.5 }} />
                        <span>No messages found matching your criteria.</span>
                    </div>
                ) : (
                    <div className="activity-list">
                        {filteredContacts.map((contact) => (
                            <div key={contact._id} className="activity-item" style={{ 
                                flexDirection: 'column', 
                                alignItems: 'flex-start',
                                padding: '25px',
                                borderBottom: '1px solid rgba(255,255,255,0.05)',
                                background: replyingTo === contact._id ? 'rgba(255,255,255,0.02)' : 'transparent',
                                transition: 'background 0.3s ease'
                            }}>
                                <div style={{ display: 'flex', width: '100%', gap: '20px' }}>
                                    {/* Avatar */}
                                    <div style={{ 
                                        width: '45px', 
                                        height: '45px', 
                                        borderRadius: '12px', 
                                        background: contact.status === 'Replied' ? 'rgba(46, 204, 113, 0.1)' : 'rgba(230, 126, 34, 0.1)',
                                        color: contact.status === 'Replied' ? '#2ecc71' : '#e67e22',
                                        display: 'flex', 
                                        alignItems: 'center', 
                                        justifyContent: 'center', 
                                        fontWeight: '600',
                                        fontSize: '1.1rem',
                                        flexShrink: 0
                                    }}>
                                        {contact.name.charAt(0).toUpperCase()}
                                    </div>
                                    
                                    {/* Content */}
                                    <div style={{ flex: 1 }}>
                                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '5px', alignItems: 'flex-start' }}>
                                            <div>
                                                <h4 style={{ color: 'white', margin: 0, fontSize: '1rem', fontWeight: '600' }}>{contact.name}</h4>
                                                <span style={{ color: '#aaa', fontSize: '0.85rem' }}>{contact.email}</span>
                                            </div>
                                            <div style={{ textAlign: 'right' }}>
                                                <span className="activity-time" style={{ display: 'block', marginBottom: '5px', fontSize: '0.8rem' }}>
                                                    {formatDate(contact.createdAt)}
                                                </span>
                                                {contact.status === 'Replied' && (
                                                    <span style={{ textTransform: 'uppercase', fontSize: '0.65rem', padding: '2px 6px', borderRadius: '4px', background: 'rgba(46, 204, 113, 0.2)', color: '#2ecc71', fontWeight: 'bold' }}>
                                                        Replied
                                                    </span>
                                                )}
                                                {contact.status === 'New' && (
                                                    <span style={{ textTransform: 'uppercase', fontSize: '0.65rem', padding: '2px 6px', borderRadius: '4px', background: 'rgba(52, 152, 219, 0.2)', color: '#3498db', fontWeight: 'bold' }}>
                                                        New
                                                    </span>
                                                )}
                                            </div>
                                        </div>
                                        
                                        <p style={{ 
                                            color: '#ddd', 
                                            fontSize: '0.95rem', 
                                            lineHeight: '1.6', 
                                            marginTop: '10px',
                                            padding: '15px',
                                            background: 'rgba(0,0,0,0.2)',
                                            borderRadius: '8px',
                                            borderLeft: `3px solid ${contact.status === 'Replied' ? '#2ecc71' : 'var(--tea-primary)'}`
                                        }}>
                                            {contact.message}
                                        </p>

                                        {/* Reply History */}
                                        {contact.replies && contact.replies.length > 0 && (
                                            <div style={{ marginTop: '20px', paddingLeft: '15px', borderLeft: '2px solid rgba(255, 255, 255, 0.1)' }}>
                                                <h5 style={{ color: '#aaa', fontSize: '0.85rem', marginBottom: '10px', textTransform: 'uppercase', letterSpacing: '1px' }}>Previous Replies</h5>
                                                {contact.replies.map((reply, index) => (
                                                    <div key={index} style={{ marginBottom: '10px', background: 'rgba(255,255,255,0.03)', padding: '12px', borderRadius: '6px' }}>
                                                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px', alignItems: 'center' }}>
                                                            <span style={{ color: 'white', fontSize: '0.9rem', fontWeight: '500' }}>{reply.subject}</span>
                                                            <span style={{ color: '#7f8c8d', fontSize: '0.75rem' }}>{formatDate(reply.repliedAt)}</span>
                                                        </div>
                                                        <p style={{ color: '#ccc', fontSize: '0.85rem', margin: 0, whiteSpace: 'pre-wrap' }}>{reply.message}</p>
                                                    </div>
                                                ))}
                                            </div>
                                        )}

                                        {/* Actions */}
                                        <div style={{ marginTop: '15px', display: 'flex', gap: '10px' }}>
                                            {replyingTo !== contact._id && (
                                                <button 
                                                    onClick={() => handleReplyClick(contact)}
                                                    style={{ 
                                                        background: 'transparent',
                                                        border: '1px solid rgba(255,255,255,0.2)',
                                                        color: '#ccc',
                                                        padding: '6px 14px',
                                                        borderRadius: '6px',
                                                        cursor: 'pointer',
                                                        fontSize: '0.85rem',
                                                        display: 'flex',
                                                        alignItems: 'center',
                                                        gap: '6px',
                                                        transition: 'all 0.2s'
                                                    }}
                                                    onMouseOver={(e) => { e.currentTarget.style.borderColor = 'white'; e.currentTarget.style.color = 'white'; }}
                                                    onMouseOut={(e) => { e.currentTarget.style.borderColor = 'rgba(255,255,255,0.2)'; e.currentTarget.style.color = '#ccc'; }}
                                                >
                                                    <Mail size={14} /> Reply
                                                </button>
                                            )}
                                        </div>

                                        {/* Reply Form */}
                                        {replyingTo === contact._id && (
                                            <div style={{ 
                                                marginTop: '20px', 
                                                background: 'rgba(30, 30, 30, 0.6)', 
                                                border: '1px solid rgba(255,255,255,0.1)',
                                                borderRadius: '12px',
                                                padding: '20px',
                                                animation: 'slideDown 0.3s ease-out'
                                            }}>
                                                <h4 style={{ color: '#white', marginBottom: '15px', fontSize: '0.95rem', borderBottom: '1px solid rgba(255,255,255,0.1)', paddingBottom: '10px' }}>
                                                    Replying to <span style={{ color: 'var(--tea-secondary)' }}>{contact.email}</span>
                                                </h4>
                                                
                                                {error && <div style={{ color: '#e74c3c', marginBottom: '10px', fontSize: '0.9rem', background: 'rgba(231, 76, 60, 0.1)', padding: '10px', borderRadius: '6px' }}>{error}</div>}
                                                {successMsg && <div style={{ color: '#2ecc71', marginBottom: '10px', fontSize: '0.9rem', background: 'rgba(46, 204, 113, 0.1)', padding: '10px', borderRadius: '6px' }}>{successMsg}</div>}

                                                <div style={{ marginBottom: '15px' }}>
                                                    <label style={{ display: 'block', color: '#aaa', fontSize: '0.8rem', marginBottom: '5px' }}>Subject</label>
                                                    <input 
                                                        type="text" 
                                                        className="form-input" 
                                                        value={replySubject}
                                                        onChange={(e) => setReplySubject(e.target.value)}
                                                        placeholder="Re: Your inquiry"
                                                    />
                                                </div>
                                                
                                                <div style={{ marginBottom: '15px' }}>
                                                    <label style={{ display: 'block', color: '#aaa', fontSize: '0.8rem', marginBottom: '5px' }}>Message Body</label>
                                                    <textarea 
                                                        className="form-input" 
                                                        rows="5" 
                                                        value={replyMessage}
                                                        onChange={(e) => setReplyMessage(e.target.value)}
                                                        placeholder="Type your response here..."
                                                        style={{ resize: 'vertical', fontFamily: 'inherit', lineHeight: '1.5' }}
                                                    ></textarea>
                                                </div>

                                                <div style={{ marginBottom: '20px' }}>
                                                    <input 
                                                        type="file" 
                                                        id="file-upload"
                                                        onChange={(e) => setReplyFile(e.target.files[0])}
                                                        style={{ display: 'none' }}
                                                    />
                                                    <div style={{ display: 'flex', alignItems: 'center', gap: '15px' }}>
                                                        <label 
                                                            htmlFor="file-upload" 
                                                            style={{ 
                                                                display: 'flex', 
                                                                alignItems: 'center', 
                                                                gap: '8px', 
                                                                background: 'rgba(255,255,255,0.08)', 
                                                                padding: '10px 16px', 
                                                                borderRadius: '8px', 
                                                                cursor: 'pointer',
                                                                color: '#ddd',
                                                                fontSize: '0.9rem',
                                                                transition: 'all 0.2s',
                                                                border: '1px solid rgba(255,255,255,0.1)'
                                                            }}
                                                            onMouseOver={(e) => { e.currentTarget.style.background = 'rgba(255,255,255,0.15)'; }}
                                                            onMouseOut={(e) => { e.currentTarget.style.background = 'rgba(255,255,255,0.08)'; }}
                                                        >
                                                            <span style={{ fontSize: '1.2rem' }}>📎</span>
                                                            {replyFile ? 'Change File' : 'Attach File'}
                                                        </label>
                                                        
                                                        {replyFile && (
                                                            <div style={{ 
                                                                display: 'flex', 
                                                                alignItems: 'center', 
                                                                gap: '10px',
                                                                background: 'rgba(46, 204, 113, 0.15)', 
                                                                padding: '8px 12px', 
                                                                borderRadius: '6px',
                                                                border: '1px solid rgba(46, 204, 113, 0.3)'
                                                            }}>
                                                                <span style={{ color: '#2ecc71', fontSize: '0.85rem', maxWidth: '200px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                                                                    {replyFile.name}
                                                                </span>
                                                                <button 
                                                                    onClick={() => setReplyFile(null)}
                                                                    style={{ background: 'none', border: 'none', color: '#e74c3c', cursor: 'pointer', display: 'flex', alignItems: 'center' }}
                                                                    title="Remove file"
                                                                >
                                                                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                                                                </button>
                                                            </div>
                                                        )}
                                                    </div>
                                                </div>

                                                <div style={{ display: 'flex', gap: '10px', justifyContent: 'flex-end' }}>
                                                    <button 
                                                        className="btn" 
                                                        onClick={handleCancelReply}
                                                        disabled={sending}
                                                        style={{ background: 'transparent', border: '1px solid rgba(255,255,255,0.2)', color: '#ccc' }}
                                                    >
                                                        Cancel
                                                    </button>
                                                    <button 
                                                        className="btn btn-primary" 
                                                        onClick={() => handleSendReply(contact._id)}
                                                        disabled={sending}
                                                        style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
                                                    >
                                                        {sending ? 'Sending...' : <><Mail size={16} /> Send Email</>}
                                                    </button>
                                                </div>
                                            </div>
                                        )}
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>
            <style>{`
                @keyframes slideDown {
                    from { opacity: 0; transform: translateY(-10px); }
                    to { opacity: 1; transform: translateY(0); }
                }
                
                /* Ensure dropdown options are visible in dark mode */
                select option {
                    background-color: #2c3e50;
                    color: white;
                }
                
                /* Improve placeholder visibility */
                .form-input::placeholder {
                    color: rgba(255, 255, 255, 0.7);
                    opacity: 1; /* Firefox */
                }
            `}</style>
        </div>
    );
};

export default Feedback;
