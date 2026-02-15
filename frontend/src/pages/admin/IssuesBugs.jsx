import React, { useState, useEffect, useCallback } from 'react';
import { AlertTriangle, RefreshCw, Filter, Search, CheckCircle, Clock, XCircle, Database, Server, Zap, CheckCircle2, History, ChevronDown, ListFilter, SlidersHorizontal } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import '../../css/Dashboard.css';

const IssuesBugs = () => {
    const { user } = useAuth();
    const [alerts, setAlerts] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [activeTab, setActiveTab] = useState('active');
    
    // Filters
    const [severityFilter, setSeverityFilter] = useState('all');
    const [serviceFilter, setServiceFilter] = useState('all');
    const [dateRange, setDateRange] = useState('all');
    const [sortOrder, setSortOrder] = useState('newest');

    const fetchAlerts = useCallback(async () => {
        setLoading(true);
        try {
            const params = new URLSearchParams({
                severity: severityFilter,
                service: serviceFilter,
                status: activeTab,
                dateRange,
                sort: sortOrder
            });

            const response = await fetch(`/api/admin/alerts/history?${params}`, {
                headers: {
                    'Authorization': `Bearer ${user.token}`
                }
            });

            const data = await response.json();
            if (response.ok) {
                setAlerts(data.alerts || []);
            } else {
                console.error('Failed to fetch alerts');
            }
        } catch (error) {
            console.error('Error fetching alerts:', error);
        } finally {
            setLoading(false);
        }
    }, [user.token, severityFilter, serviceFilter, activeTab, dateRange, sortOrder]);

    useEffect(() => {
        fetchAlerts();
    }, [fetchAlerts]);

    const handleStatusChange = async (id, newStatus) => {
        try {
            const response = await fetch(`/api/admin/alerts/${id}/status`, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${user.token}`
                },
                body: JSON.stringify({ status: newStatus })
            });

            if (response.ok) {
                // Instantly remove from view
                setAlerts(prev => prev.filter(a => a._id !== id));
            } else {
                const errorData = await response.json();
                console.error('Failed to update status:', errorData.message);
                alert('Action failed. Please refresh and try again.');
            }
        } catch (error) {
            console.error('Error updating status:', error);
        }
    };

    const filteredAlerts = alerts.filter(alert => {
        if (!searchTerm) return true;
        const searchLower = searchTerm.toLowerCase();
        return (
            alert.systemName?.toLowerCase().includes(searchLower) ||
            alert.issues.some(issue => issue.toLowerCase().includes(searchLower))
        );
    });

    const getSeverityColor = (severity) => {
        switch(severity) {
            case 'critical': return '#ff3b30';
            case 'warning': return '#ff9500';
            case 'info': return '#007aff';
            default: return '#8e8e93';
        }
    };

    const getServiceIcon = (serviceName) => {
        if (!serviceName) return <Server size={22} />;
        const name = serviceName.toLowerCase();
        if (name.includes('database') || name.includes('db')) return <Database size={22} />;
        if (name.includes('ai') || name.includes('disease') || name.includes('yield') || name.includes('maturity')) return <Zap size={22} />;
        return <Server size={22} />;
    };

    const formatTimestamp = (timestamp) => {
        const date = new Date(timestamp);
        return date.toLocaleString('en-US', { 
            month: 'short', 
            day: 'numeric', 
            hour: '2-digit', 
            minute: '2-digit' 
        });
    };

    return (
        <div className="dashboard-container">
            <style>
                {`
                    .dashboard-card::placeholder {
                        color: rgba(255, 255, 255, 0.6) !important;
                    }
                `}
            </style>
            <header className="dashboard-header" style={{ alignItems: 'center', marginBottom: '40px' }}>
                <div>
                    <h1 style={{ margin: 0, background: 'linear-gradient(90deg, #fff, #aaa)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
                        Issues & Logs
                    </h1>
                    <p className="dashboard-subtitle" style={{ color: '#fff', opacity: 0.9, marginTop: '5px', marginBottom: 0 }}>Real-time system diagnostics & anomaly tracking</p>
                </div>

                <div className="header-actions">
                    <button 
                        onClick={() => setActiveTab('active')}
                        style={{
                            background: activeTab === 'active' ? 'rgba(231, 76, 60, 0.3)' : 'rgba(255, 255, 255, 0.05)',
                            border: `1px solid ${activeTab === 'active' ? '#e74c3c' : 'rgba(255, 255, 255, 0.15)'}`,
                            color: activeTab === 'active' ? '#fff' : '#fff',
                            padding: '10px 24px',
                            fontWeight: '800',
                            borderRadius: '10px',
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                            boxShadow: activeTab === 'active' ? '0 0 15px rgba(231, 76, 60, 0.3)' : 'none'
                        }}
                        onMouseEnter={(e) => {
                            e.currentTarget.style.background = 'rgba(231, 76, 60, 0.6)';
                            e.currentTarget.style.borderColor = '#e74c3c';
                            e.currentTarget.style.color = '#fff';
                            e.currentTarget.style.boxShadow = '0 0 20px rgba(231, 76, 60, 0.4)';
                            e.currentTarget.style.transform = 'translateY(-2px)';
                        }}
                        onMouseLeave={(e) => {
                            e.currentTarget.style.background = activeTab === 'active' ? 'rgba(231, 76, 60, 0.3)' : 'rgba(255, 255, 255, 0.05)';
                            e.currentTarget.style.borderColor = activeTab === 'active' ? '#e74c3c' : 'rgba(255, 255, 255, 0.15)';
                            e.currentTarget.style.color = activeTab === 'active' ? '#fff' : '#aaa';
                            e.currentTarget.style.boxShadow = activeTab === 'active' ? '0 0 15px rgba(231, 76, 60, 0.3)' : 'none';
                            e.currentTarget.style.transform = 'translateY(0)';
                        }}
                    >
                        <AlertTriangle size={18} style={{ marginRight: '8px' }} /> ACTIVE
                    </button>
                    <button 
                        onClick={() => setActiveTab('resolved')}
                        style={{
                            background: activeTab === 'resolved' ? 'rgba(46, 204, 113, 0.3)' : 'rgba(255, 255, 255, 0.05)',
                            border: `1px solid ${activeTab === 'resolved' ? '#2ecc71' : 'rgba(255, 255, 255, 0.15)'}`,
                            color: activeTab === 'resolved' ? '#fff' : '#aaa',
                            padding: '10px 24px',
                            fontWeight: '800',
                            borderRadius: '10px',
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                            boxShadow: activeTab === 'resolved' ? '0 0 15px rgba(46, 204, 113, 0.3)' : 'none'
                        }}
                        onMouseEnter={(e) => {
                            e.currentTarget.style.background = 'rgba(46, 204, 113, 0.6)';
                            e.currentTarget.style.borderColor = '#2ecc71';
                            e.currentTarget.style.color = '#fff';
                            e.currentTarget.style.boxShadow = '0 0 20px rgba(46, 204, 113, 0.4)';
                            e.currentTarget.style.transform = 'translateY(-2px)';
                        }}
                        onMouseLeave={(e) => {
                            e.currentTarget.style.background = activeTab === 'resolved' ? 'rgba(46, 204, 113, 0.3)' : 'rgba(255, 255, 255, 0.05)';
                            e.currentTarget.style.borderColor = activeTab === 'resolved' ? '#2ecc71' : 'rgba(255, 255, 255, 0.15)';
                            e.currentTarget.style.color = activeTab === 'resolved' ? '#fff' : '#aaa';
                            e.currentTarget.style.boxShadow = activeTab === 'resolved' ? '0 0 15px rgba(46, 204, 113, 0.3)' : 'none';
                            e.currentTarget.style.transform = 'translateY(0)';
                        }}
                    >
                        <CheckCircle2 size={18} style={{ marginRight: '8px' }} /> RESOLVED
                    </button>
                    
                    <button 
                        onClick={fetchAlerts}
                        className="refresh-btn"
                        style={{ marginLeft: '10px' }}
                    >
                        <RefreshCw size={20} className={loading ? 'spinning' : ''} />
                    </button>
                </div>
            </header>

            <div style={{ 
                display: 'flex', 
                gap: '12px', 
                marginBottom: '30px', 
                alignItems: 'stretch',
                width: '100%'
            }}>
                <div style={{ position: 'relative', flex: 1, display: 'flex' }}>
                    <Search size={18} style={{ position: 'absolute', left: '15px', top: '50%', transform: 'translateY(-50%)', color: '#fff', zIndex: 1 }} />
                    <input 
                        className="dashboard-card"
                        type="text" 
                        placeholder="Search logs by system or message..." 
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        style={{
                            width: '100%',
                            padding: '0 15px 0 45px',
                            background: 'rgba(255, 255, 255, 0.05)',
                            border: '1px solid rgba(255, 255, 255, 0.1)',
                            borderRadius: '10px',
                            color: '#fff',
                            fontSize: '0.95rem',
                            height: '48px',
                            margin: 0
                        }}
                    />
                </div>

                <select 
                    className="dashboard-card"
                    value={severityFilter} 
                    onChange={(e) => setSeverityFilter(e.target.value)}
                    style={{
                        padding: '0 40px 0 20px',
                        background: 'rgba(255, 255, 255, 0.05)',
                        border: '1px solid rgba(255, 255, 255, 0.1)',
                        borderRadius: '10px',
                        color: '#fff',
                        cursor: 'pointer',
                        height: '48px',
                        margin: 0,
                        appearance: 'none',
                        WebkitAppearance: 'none',
                        minWidth: '180px',
                        flexShrink: 0
                    }}
                >
                    <option value="all" style={{ background: '#111' }}>Every Severity</option>
                    <option value="critical" style={{ background: '#111' }}>Critical</option>
                    <option value="warning" style={{ background: '#111' }}>Warning</option>
                    <option value="info" style={{ background: '#111' }}>Info</option>
                </select>

                <select 
                    className="dashboard-card"
                    value={serviceFilter} 
                    onChange={(e) => setServiceFilter(e.target.value)}
                    style={{
                        padding: '0 40px 0 20px',
                        background: 'rgba(255, 255, 255, 0.05)',
                        border: '1px solid rgba(255, 255, 255, 0.1)',
                        borderRadius: '10px',
                        color: '#fff',
                        cursor: 'pointer',
                        height: '48px',
                        margin: 0,
                        appearance: 'none',
                        WebkitAppearance: 'none',
                        minWidth: '180px',
                        flexShrink: 0
                    }}
                >
                    <option value="all" style={{ background: '#111' }}>All Systems</option>
                    <option value="Main Web App" style={{ background: '#111' }}>Web App</option>
                    <option value="Database" style={{ background: '#111' }}>Database</option>
                    <option value="AI Services" style={{ background: '#111' }}>AI Nodes</option>
                </select>
            </div>

            {loading ? (
                <div style={{ padding: '100px', textAlign: 'center' }}>
                    <RefreshCw size={40} className="spinning" style={{ color: '#2ecc71' }} />
                </div>
            ) : filteredAlerts.length === 0 ? (
                <div className="dashboard-card" style={{ 
                    padding: '80px 40px', 
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                    textAlign: 'center', 
                    borderStyle: 'dashed',
                    minHeight: '400px',
                    width: '100%'
                }}>
                    <div className="system-status" style={{ 
                        marginBottom: '30px', 
                        display: 'flex', 
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: '12px',
                        padding: '12px 24px',
                        borderRadius: '30px',
                        marginRight: 0 
                    }}>
                        <div className="status-dot" style={{ width: '10px', height: '10px' }}></div>
                        <span style={{ fontWeight: '700', fontSize: '1rem' }}>Systems Healthy</span>
                    </div>
                    <h2 style={{ color: '#fff', fontSize: '2.2rem', fontWeight: '800', margin: '0 0 15px 0', letterSpacing: '-0.5px' }}>No anomalies reported</h2>
                    <p style={{ color: '#fff', opacity: 0.6, margin: 0, fontSize: '1.1rem', maxWidth: '500px' }}>Monitor is active and scanning for infrastructure issues.</p>
                </div>
            ) : (
                <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                    {filteredAlerts.map((alert) => (
                        <div key={alert._id} className="dashboard-card" style={{ padding: '0', overflow: 'hidden' }}>
                            <div style={{ padding: '24px', display: 'flex', alignItems: 'center', background: 'rgba(255, 255, 255, 0.02)' }}>
                                <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
                                    <div className="stat-icon-wrapper" style={{ 
                                        color: getSeverityColor(alert.severity),
                                        background: `${getSeverityColor(alert.severity)}15`
                                    }}>
                                        {getServiceIcon(alert.systemName)}
                                    </div>
                                    <div>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                                            <h3 style={{ margin: 0, color: '#fff', fontWeight: '700' }}>{alert.systemName}</h3>
                                            <div style={{ 
                                                width: '8px', 
                                                height: '8px', 
                                                borderRadius: '50%', 
                                                background: getSeverityColor(alert.severity),
                                                boxShadow: `0 0 10px ${getSeverityColor(alert.severity)}`
                                            }}></div>
                                        </div>
                                        <div style={{ display: 'flex', alignItems: 'center', gap: '15px', marginTop: '6px' }}>
                                            <span style={{ fontSize: '0.85rem', color: '#fff', opacity: 0.8, display: 'flex', alignItems: 'center', gap: '6px' }}>
                                                <Clock size={14} /> {formatTimestamp(alert.createdAt)}
                                            </span>
                                            <span style={{ 
                                                fontSize: '0.8rem', 
                                                color: getSeverityColor(alert.severity), 
                                                fontWeight: '800', 
                                                textTransform: 'uppercase'
                                            }}>
                                                {alert.severity}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div style={{ padding: '24px', borderTop: '1px solid rgba(255, 255, 255, 0.05)' }}>
                                <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                                    {alert.issues.map((issue, idx) => (
                                        <div 
                                            key={idx} 
                                            style={{ 
                                                fontSize: '0.95rem',
                                                color: '#fff',
                                                background: 'rgba(0,0,0,0.2)',
                                                padding: '12px 18px',
                                                borderRadius: '8px',
                                                border: '1px solid rgba(255,255,255,0.05)',
                                                lineHeight: '1.6',
                                                fontFamily: 'monospace',
                                                opacity: 0.95
                                            }}
                                        >
                                            <span style={{ color: activeTab === 'active' ? '#e74c3c' : '#2ecc71', marginRight: '12px', fontWeight: '800' }}>»</span>
                                            {issue}
                                        </div>
                                    ))}
                                </div>
                                
                                <div style={{ 
                                    marginTop: '20px', 
                                    display: 'flex', 
                                    justifyContent: 'space-between', 
                                    alignItems: 'center' 
                                }}>
                                    {activeTab === 'resolved' ? (
                                        <div style={{ 
                                            padding: '10px 15px',
                                            background: 'rgba(46, 204, 113, 0.1)',
                                            borderRadius: '8px',
                                            display: 'flex',
                                            alignItems: 'center',
                                            gap: '10px',
                                            color: '#2ecc71',
                                            fontWeight: '600',
                                            fontSize: '0.9rem',
                                            border: '1px solid rgba(46, 204, 113, 0.2)'
                                        }}>
                                            <CheckCircle2 size={18} /> Verified Resolved {alert.resolvedAt ? `at ${new Date(alert.resolvedAt).toLocaleString()}` : 'successfully'}
                                        </div>
                                    ) : (
                                        <div style={{ color: '#fff', fontSize: '0.85rem', fontWeight: '500', opacity: 0.7 }}>
                                            Action required to maintain system integrity.
                                        </div>
                                    )}

                                    <button 
                                        onClick={() => handleStatusChange(alert._id, activeTab === 'active' ? 'resolved' : 'active')}
                                        style={{
                                            background: activeTab === 'active' ? 'rgba(46, 204, 113, 0.15)' : 'rgba(52, 152, 219, 0.15)',
                                            border: `1px solid ${activeTab === 'active' ? '#2ecc71' : '#3498db'}`,
                                            color: activeTab === 'active' ? '#2ecc71' : '#3498db',
                                            padding: '10px 28px',
                                            borderRadius: '10px',
                                            fontWeight: '800',
                                            fontSize: '0.9rem',
                                            cursor: 'pointer',
                                            transition: 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)',
                                            boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
                                        }}
                                        onMouseEnter={(e) => {
                                            e.currentTarget.style.background = activeTab === 'active' ? '#2ecc71' : '#3498db';
                                            e.currentTarget.style.color = '#fff';
                                            e.currentTarget.style.boxShadow = `0 0 20px ${activeTab === 'active' ? 'rgba(46, 204, 113, 0.4)' : 'rgba(52, 152, 219, 0.4)'}`;
                                            e.currentTarget.style.transform = 'translateY(-2px)';
                                        }}
                                        onMouseLeave={(e) => {
                                            e.currentTarget.style.background = activeTab === 'active' ? 'rgba(46, 204, 113, 0.15)' : 'rgba(52, 152, 219, 0.15)';
                                            e.currentTarget.style.color = activeTab === 'active' ? '#2ecc71' : '#3498db';
                                            e.currentTarget.style.boxShadow = '0 4px 6px rgba(0,0,0,0.1)';
                                            e.currentTarget.style.transform = 'translateY(0)';
                                        }}
                                    >
                                        {activeTab === 'active' ? 'RESOLVE' : 'RE-OPEN LOG'}
                                    </button>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
};

export default IssuesBugs;
