
import { Leaf, LogOut } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { useNavigate, Link, Outlet } from 'react-router-dom';
import TeaBackground from '../components/TeaBackground';
import '../css/AdminLayout.css';

const AdminLayout = () => {
    const { logout } = useAuth();
    const navigate = useNavigate();

    const handleLogout = () => {
        logout();
        // Force a hard redirect to clear React state and browser history stack context
        window.location.href = '/'; 
    };

    // Secondary Auth Check: Force redirect if no user is found in context
    // This catches scenarios where the router might render the component from memory/history
    if (!useAuth().user) {
        window.location.href = '/login';
        return null;
    }

    return (
        <div className="admin-container">
            <TeaBackground />
            <aside className="admin-sidebar glass-panel">
                <div className="sidebar-header">
                     <Link to="/" className="navbar-logo" style={{ textDecoration: 'none', marginRight: 'auto' }}>
                        <Leaf className="logo-icon" size={24} />
                        <span style={{ fontSize: '1.2rem' }}>iTeaGrow</span>
                    </Link>
                    <span className="badge-admin">Admin</span>
                </div>
                <nav style={{ flex: 1 }}>
                    <ul>
                        <li><Link to="/admin/dashboard" className="nav-link">Dashboard</Link></li>
                        <li><Link to="/admin/users" className="nav-link">User Management</Link></li>
                        <li><Link to="/admin/devices" className="nav-link">Device Tracking</Link></li>
                        <li><Link to="/admin/data" className="nav-link">Data Collection</Link></li>
                        <li><Link to="/admin/health" className="nav-link">System Health</Link></li>
                        <li><Link to="/admin/issues" className="nav-link">Issues & Bugs</Link></li>
                        <li><Link to="/admin/feedback" className="nav-link">Feedback</Link></li>
                    </ul>
                </nav>
                
                <div className="sidebar-footer" style={{ borderTop: '1px solid rgba(255,255,255,0.1)', paddingTop: '20px', marginTop: '20px' }}>
                    <button onClick={handleLogout} className="nav-link" style={{ 
                        width: '100%', 
                        textAlign: 'left', 
                        background: 'rgba(231, 76, 60, 0.1)', 
                        color: '#ff8a80', 
                        border: '1px solid rgba(231, 76, 60, 0.2)',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '10px'
                    }}>
                        <LogOut size={18} /> Logout
                    </button>
                </div>
            </aside>
            <main className="admin-content">
                <Outlet />
            </main>
        </div>
    );
};

export default AdminLayout;
