import React from 'react';
import { Users, Smartphone, Server, AlertTriangle, Activity, Database, Clock, ShieldCheck, Sun, Camera, Droplets, TrendingUp, CloudRain } from 'lucide-react';
import '../../css/Dashboard.css';

const AdminDashboard = () => {
    return (
        <div className="dashboard-container">
            <header className="dashboard-header">
                <div>
                    <h1>Admin Overview</h1>
                    <p className="dashboard-subtitle">Welcome back, Administrator. System is operational.</p>
                </div>
                <div className="header-actions">
                    <span className="system-status">
                        <span className="status-dot"></span> System Online
                    </span>
                    <span className="last-updated">Updated: Just now</span>
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
                            <span className="card-value">1,240</span>
                            <span className="stat-trend positive">+12%</span>
                        </div>
                        <p className="card-sub">850 Farmers, 390 Researchers</p>
                    </div>
                </div>

                <div className="dashboard-card stat-card">
                    <div className="stat-icon-wrapper green">
                        <Smartphone size={24} />
                    </div>
                    <div className="stat-content">
                        <span className="card-title">Active Devices</span>
                        <div className="card-value-group">
                            <span className="card-value">58</span>
                            <span className="stat-trend positive">+5</span>
                        </div>
                        <p className="card-sub">42 Online, 16 Offline/Syncing</p>
                    </div>
                </div>

                <div className="dashboard-card stat-card">
                    <div className="stat-icon-wrapper orange">
                        <AlertTriangle size={24} />
                    </div>
                    <div className="stat-content">
                        <span className="card-title">Pending Alerts</span>
                        <div className="card-value-group">
                            <span className="card-value">12</span>
                            <span className="stat-trend negative">+3</span>
                        </div>
                        <p className="card-sub">3 Critical (Fertilizer/Pest)</p>
                    </div>
                </div>

                <div className="dashboard-card stat-card">
                    <div className="stat-icon-wrapper purple">
                        <Database size={24} />
                    </div>
                    <div className="stat-content">
                        <span className="card-title">Data Points</span>
                        <div className="card-value-group">
                            <span className="card-value">85k</span>
                            <span className="stat-trend positive">+2.4k</span>
                        </div>
                        <p className="card-sub">Scans & IoT Readings</p>
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
                        <div className="activity-item">
                            <Clock size={16} className="activity-icon" />
                            <div className="activity-details">
                                <span className="activity-text">New user registration: <strong>Estate_Mgr_04</strong></span>
                                <span className="activity-time">2 mins ago</span>
                            </div>
                        </div>
                        <div className="activity-item">
                            <AlertTriangle size={16} className="activity-icon warning" />
                            <div className="activity-details">
                                <span className="activity-text">High Phoshorous Alert - <strong>Zone B2</strong></span>
                                <span className="activity-time">15 mins ago</span>
                            </div>
                        </div>
                        <div className="activity-item">
                            <Smartphone size={16} className="activity-icon bg-success" />
                            <div className="activity-details">
                                <span className="activity-text">Device <strong>IoT-Gen2-089</strong> synced successfully</span>
                                <span className="activity-time">42 mins ago</span>
                            </div>
                        </div>
                        <div className="activity-item">
                            <ShieldCheck size={16} className="activity-icon" />
                            <div className="activity-details">
                                <span className="activity-text">System backup completed</span>
                                <span className="activity-time">2 hours ago</span>
                            </div>
                        </div>
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
                                <span>API Latency</span>
                                <span className="health-value">42ms</span>
                            </div>
                            <div className="health-bar-bg">
                                <div className="health-bar-fill" style={{ width: '15%' }}></div>
                            </div>
                        </div>
                        <div className="health-item">
                            <div className="health-label">
                                <span>Database Load</span>
                                <span className="health-value">28%</span>
                            </div>
                            <div className="health-bar-bg">
                                <div className="health-bar-fill" style={{ width: '28%' }}></div>
                            </div>
                        </div>
                        <div className="health-item">
                            <div className="health-label">
                                <span>Storage Usage</span>
                                <span className="health-value">64%</span>
                            </div>
                            <div className="health-bar-bg">
                                <div className="health-bar-fill warning" style={{ width: '64%' }}></div>
                            </div>
                        </div>
                        <div className="health-status">
                            <ShieldCheck size={40} className="health-status-icon" />
                            <div>
                                <h4 style={{ color: 'var(--tea-fresh-leaf)' }}>Healthy</h4>
                                <p>All systems operational</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default AdminDashboard;
