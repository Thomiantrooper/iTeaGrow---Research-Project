import React, { useState, useEffect } from 'react';
import { Users, MessageSquare, Server, AlertTriangle, Activity, Database, Clock, ShieldCheck, Mail, RefreshCw } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { useHealth } from '../../context/HealthContext';
import '../../css/Dashboard.css';

const AdminDashboard = () => {
    const { user } = useAuth();
    const healthContext = useHealth();
    const health = healthContext?.health || {};
    
    const [stats, setStats] = useState({
        users: { total: 0, breakdown: {} },
        contacts: { total: 0, pending: 0, replied: 0 },
        alerts: { total: 0, last24h: 0 },
        loading: true
    });
    const [activities, setActivities] = useState([]);

    useEffect(() => {
        // Only fetch data if user is authenticated
        if (user && user.token) {
            fetchDashboardData();
        }
    }, [user]);

    const fetchDashboardData = async () => {
        try {
            // Use token from AuthContext
            if (!user || !user.token) {
                console.log('No user or token found in AuthContext');
                setStats(prev => ({ ...prev, loading: false }));
                return;
            }
            
            const headers = { 'Authorization': `Bearer ${user.token}` };

            // Fetch all stats in parallel
            const [usersRes, contactsRes, alertsRes, activityRes] = await Promise.all([
                fetch('/api/users/stats', { headers }),
                fetch('/api/contact/stats', { headers }),
                fetch('/api/admin/alert-stats', { headers }),
                fetch('/api/admin/recent-activity', { headers })
            ]);

            const [users, contacts, alerts, activity] = await Promise.all([
                usersRes.json(),
                contactsRes.json(),
                alertsRes.json(),
                activityRes.json()
            ]);

            console.log('📊 Dashboard Data Fetched:', { users, contacts, alerts, activity });

            setStats({ users, contacts, alerts, loading: false });
            setActivities(activity);
        } catch (error) {
            console.error('❌ Error fetching dashboard data:', error);
            setStats(prev => ({ ...prev, loading: false }));
        }
    };

    const formatTimeAgo = (timestamp) => {
        const seconds = Math.floor((new Date() - new Date(timestamp)) / 1000);
        if (seconds < 60) return `${seconds}s ago`;
        const minutes = Math.floor(seconds / 60);
        if (minutes < 60) return `${minutes}m ago`;
        const hours = Math.floor(minutes / 60);
        if (hours < 24) return `${hours}h ago`;
        return `${Math.floor(hours / 24)}d ago`;
    };

    const getActivityIcon = (type) => {
        switch (type) {
            case 'contact': return <Mail size={16} className="activity-icon" />;
            case 'login': return <Users size={16} className="activity-icon bg-success" />;
            case 'alert': return <AlertTriangle size={16} className="activity-icon warning" />;
            default: return <Clock size={16} className="activity-icon" />;
        }
    };

    // Calculate total data points (with safety checks)
    const totalDataPoints = (stats.contacts?.total || 0) + (stats.alerts?.total || 0);

    const handleRefresh = () => {
        setStats(prev => ({ ...prev, loading: true }));
        fetchDashboardData();
    };

    return (
        <div className="dashboard-container">
            <header className="dashboard-header">
                <div>
                    <h1>Admin Overview</h1>
                    <p className="dashboard-subtitle">Welcome back, Administrator. System is operational.</p>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: '12px' }}>
                    {/* Refresh Button - Icon Only */}
                    <button 
                        onClick={handleRefresh} 
                        disabled={stats.loading}
                        title="Refresh dashboard data"
                        style={{ 
                            background: 'rgba(46, 204, 113, 0.2)',
                            border: '1px solid rgba(46, 204, 113, 0.4)',
                            color: '#2ecc71',
                            padding: '10px',
                            borderRadius: '10px',
                            cursor: 'pointer',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            transition: 'all 0.3s ease',
                            boxShadow: stats.loading ? '0 0 20px rgba(46, 204, 113, 0.4)' : 'none',
                            opacity: stats.loading ? 0.8 : 1
                        }}
                        onMouseEnter={(e) => {
                            if (!stats.loading) {
                                e.currentTarget.style.background = 'rgba(46, 204, 113, 0.3)';
                                e.currentTarget.style.transform = 'translateY(-2px)';
                                e.currentTarget.style.boxShadow = '0 4px 12px rgba(46, 204, 113, 0.3)';
                            }
                        }}
                        onMouseLeave={(e) => {
                            e.currentTarget.style.background = 'rgba(46, 204, 113, 0.2)';
                            e.currentTarget.style.transform = 'translateY(0)';
                            e.currentTarget.style.boxShadow = 'none';
                        }}
                    >
                        <RefreshCw size={20} className={stats.loading ? 'spinning' : ''} />
                    </button>

                    {/* Status Indicators */}
                    <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                            <span className="status-dot"></span>
                            <span style={{ color: '#2ecc71', fontSize: '0.85rem', fontWeight: '500' }}>System Online</span>
                        </div>
                        <span style={{ color: '#aaa', fontSize: '0.85rem', fontWeight: '500' }}>
                            Updated: Just now
                        </span>
                    </div>
                </div>
            </header>

            {/* Key Metrics Grid */}
            <div className="dashboard-grid">
                <div className="dashboard-card stat-card">
                    <div className="stat-icon-wrapper blue">
                        <Users size={24} />
                    </div>
                    <div className="stat-content">
                        <span className="card-title">Total Users</span>
                        <div className="card-value-group">
                            <span className="card-value">
                                {stats.loading ? '...' : stats.users.total}
                            </span>
                        </div>
                        <p className="card-sub">
                            {(stats.users.breakdown?.admin || 0)} Admin, {((stats.users.breakdown?.farmer || 0) + (stats.users.breakdown?.researcher || 0))} Normal Users
                        </p>
                    </div>
                </div>

                <div className="dashboard-card stat-card">
                    <div className="stat-icon-wrapper green">
                        <MessageSquare size={24} />
                    </div>
                    <div className="stat-content">
                        <span className="card-title">Contact Messages</span>
                        <div className="card-value-group">
                            <span className="card-value">
                                {stats.loading ? '...' : (stats.contacts?.total || 0)}
                            </span>
                        </div>
                        <p className="card-sub">
                            {((stats.contacts?.total || 0) - (stats.contacts?.replied || 0))} Pending, {stats.contacts?.replied || 0} Replied
                        </p>
                    </div>
                </div>

                <div className="dashboard-card stat-card">
                    <div className="stat-icon-wrapper orange">
                        <AlertTriangle size={24} />
                    </div>
                    <div className="stat-content">
                        <span className="card-title">System Alerts</span>
                        <div className="card-value-group">
                            <span className="card-value">
                                {stats.loading ? '...' : (stats.alerts?.last24h || 0)}
                            </span>
                            {(stats.alerts?.last24h || 0) > 0 && (
                                <span className="stat-trend negative">Last 24h</span>
                            )}
                        </div>
                        <p className="card-sub">
                            {stats.alerts?.total || 0} Total Alerts Logged
                        </p>
                    </div>
                </div>

                <div className="dashboard-card stat-card">
                    <div className="stat-icon-wrapper purple">
                        <Database size={24} />
                    </div>
                    <div className="stat-content">
                        <span className="card-title">Data Points</span>
                        <div className="card-value-group">
                            <span className="card-value">
                                {stats.loading ? '...' : totalDataPoints.toLocaleString()}
                            </span>
                        </div>
                        <p className="card-sub">Contacts & System Logs</p>
                    </div>
                </div>
            </div>

            {/* Secondary Section: Activity & Health */}
            <div className="dashboard-secondary-grid">
                {/* Recent Activity Feed */}
                <div className="dashboard-card activity-section">
                    <div className="card-header">
                        <Activity size={20} className="section-icon" />
                        <h3>Recent Activity</h3>
                    </div>
                    <div className="activity-list">
                        {activities.length === 0 ? (
                            <div className="activity-item">
                                <Clock size={16} className="activity-icon" />
                                <div className="activity-details">
                                    <span className="activity-text">No recent activity</span>
                                </div>
                            </div>
                        ) : (
                            activities.map((activity, index) => (
                                <div key={index} className="activity-item">
                                    {getActivityIcon(activity.type)}
                                    <div className="activity-details">
                                        <span className="activity-text">{activity.text}</span>
                                        <span className="activity-time">{formatTimeAgo(activity.time)}</span>
                                    </div>
                                </div>
                            ))
                        )}
                    </div>
                </div>

                {/* System Health */}
                <div className="dashboard-card health-section">
                    <div className="card-header">
                        <Server size={20} className="section-icon" />
                        <h3>System Health</h3>
                    </div>
                    <div className="health-metrics">
                        <div className="health-item">
                            <div className="health-label">
                                <span>Backend API</span>
                                <span className="health-value" style={{ 
                                    color: healthContext?.webAppHealthData ? '#2ecc71' : '#e74c3c' 
                                }}>
                                    {healthContext?.webAppLoading ? 'CHECKING...' : (healthContext?.webAppHealthData ? 'ONLINE' : 'OFFLINE')}
                                </span>
                            </div>
                            <div className="health-bar-bg">
                                <div 
                                    className={`health-bar-fill ${healthContext?.webAppHealthData ? '' : 'warning'}`} 
                                    style={{ width: healthContext?.webAppHealthData ? '100%' : '0%' }}
                                ></div>
                            </div>
                        </div>
                        <div className="health-item">
                            <div className="health-label">
                                <span>Database</span>
                                <span className="health-value" style={{ 
                                    color: healthContext?.healthData?.dbState === 1 ? '#2ecc71' : '#e74c3c' 
                                }}>
                                    {healthContext?.loading ? 'CHECKING...' : (healthContext?.healthData?.dbState === 1 ? 'CONNECTED' : 'DISCONNECTED')}
                                </span>
                            </div>
                            <div className="health-bar-bg">
                                <div 
                                    className={`health-bar-fill ${healthContext?.healthData?.dbState === 1 ? '' : 'warning'}`} 
                                    style={{ width: healthContext?.healthData?.dbState === 1 ? '100%' : '0%' }}
                                ></div>
                            </div>
                        </div>
                        <div className="health-item">
                            <div className="health-label">
                                <span>AI Services</span>
                                <span className="health-value" style={{ 
                                    color: (healthContext?.aiHealthData || healthContext?.yieldHealthData || healthContext?.maturityHealthData) ? '#2ecc71' : '#e74c3c' 
                                }}>
                                    {(healthContext?.aiLoading || healthContext?.yieldLoading || healthContext?.maturityLoading) ? 'CHECKING...' : 
                                     (healthContext?.aiHealthData || healthContext?.yieldHealthData || healthContext?.maturityHealthData) ? 'ONLINE' : 'OFFLINE'}
                                </span>
                            </div>
                            <div className="health-bar-bg">
                                <div 
                                    className={`health-bar-fill ${(healthContext?.aiHealthData || healthContext?.yieldHealthData || healthContext?.maturityHealthData) ? '' : 'warning'}`} 
                                    style={{ width: (healthContext?.aiHealthData || healthContext?.yieldHealthData || healthContext?.maturityHealthData) ? '100%' : '0%' }}
                                ></div>
                            </div>
                        </div>
                        <div className="health-status">
                            <ShieldCheck size={40} className="health-status-icon" />
                            <div>
                                <h4 style={{ color: (healthContext?.webAppHealthData && healthContext?.healthData?.dbState === 1) ? 'var(--tea-fresh-leaf)' : '#f39c12' }}>
                                    {(healthContext?.webAppHealthData && healthContext?.healthData?.dbState === 1) ? 'Healthy' : 'Degraded'}
                                </h4>
                                <p>
                                    {(healthContext?.webAppHealthData && healthContext?.healthData?.dbState === 1) 
                                        ? 'All systems operational' 
                                        : 'Some services experiencing issues'}
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default AdminDashboard;
