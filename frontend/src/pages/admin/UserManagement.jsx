
import React, { useState } from 'react';
import { Search, UserPlus, MoreVertical, Shield, Trash2, Edit } from 'lucide-react';
import '../../css/Dashboard.css'; // Reusing dashboard styles for consistency

const UserManagement = () => {
    // Mock Data
    const [users, setUsers] = useState([
        { id: 1, name: "Saman Perera", email: "saman.p@estate.lk", role: "Manager", status: "Active", lastActive: "2 mins ago" },
        { id: 2, name: "Dr. Aruna De Silva", email: "aruna.ds@tri.lk", role: "Researcher", status: "Active", lastActive: "1 day ago" },
        { id: 3, name: "Kamal Gunaratne", email: "kamal.g@gmail.com", role: "Farmer", status: "Inactive", lastActive: "5 days ago" },
        { id: 4, name: "Nimali Fernando", email: "nimali.f@agri.gov", role: "Admin", status: "Active", lastActive: "1 hour ago" },
        { id: 5, name: "Estate B - Field 1", email: "field1@estate.lk", role: "Device", status: "Active", lastActive: "Just now" },
    ]);

    const [searchTerm, setSearchTerm] = useState("");

    const filteredUsers = users.filter(user => 
        user.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
        user.role.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const getRoleColor = (role) => {
        switch(role) {
            case 'Admin': return '#e74c3c';
            case 'Manager': return '#f39c12';
            case 'Researcher': return '#9b59b6';
            case 'Farmer': return '#2ecc71';
            default: return '#95a5a6';
        }
    };

    return (
        <div className="dashboard-container">
            <header className="dashboard-header">
                <div>
                    <h1>User Management</h1>
                    <p className="dashboard-subtitle">Manage access and roles for the platform.</p>
                </div>
                <div className="header-actions">
                     <button className="btn btn-primary" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <UserPlus size={18} /> Add User
                     </button>
                </div>
            </header>

            {/* Controls */}
            <div className="dashboard-card" style={{ marginBottom: '20px', flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' }}>
                <div style={{ position: 'relative', width: '300px' }}>
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
                <div style={{ display: 'flex', gap: '10px' }}>
                    <select style={{ padding: '10px', borderRadius: '6px', background: 'rgba(255,255,255,0.1)', border: '1px solid rgba(255,255,255,0.2)', color: 'white' }}>
                        <option>All Roles</option>
                        <option>Admin</option>
                        <option>Manager</option>
                        <option>Researcher</option>
                        <option>Farmer</option>
                    </select>
                </div>
            </div>

            {/* Users Table */}
            <div className="dashboard-card" style={{ padding: '0', overflow: 'hidden' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
                    <thead>
                        <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.1)', background: 'rgba(255,255,255,0.05)' }}>
                            <th style={{ padding: '16px 20px', color: '#ddd', fontWeight: '500', fontSize: '0.9rem' }}>User</th>
                            <th style={{ padding: '16px 20px', color: '#ddd', fontWeight: '500', fontSize: '0.9rem' }}>Role</th>
                            <th style={{ padding: '16px 20px', color: '#ddd', fontWeight: '500', fontSize: '0.9rem' }}>Status</th>
                            <th style={{ padding: '16px 20px', color: '#ddd', fontWeight: '500', fontSize: '0.9rem' }}>Last Active</th>
                            <th style={{ padding: '16px 20px', color: '#ddd', fontWeight: '500', fontSize: '0.9rem', textAlign: 'right' }}>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredUsers.map(user => (
                            <tr key={user.id} style={{ borderBottom: '1px solid rgba(255,255,255,0.05)', transition: 'background 0.2s' }} className="table-row">
                                <td style={{ padding: '16px 20px' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                        <div style={{ width: '36px', height: '36px', borderRadius: '50%', background: 'rgba(255,255,255,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#eee', fontWeight: '600' }}>
                                            {user.name.charAt(0)}
                                        </div>
                                        <div>
                                            <div style={{ color: 'white', fontWeight: '500' }}>{user.name}</div>
                                            <div style={{ color: '#ccc', fontSize: '0.85rem' }}>{user.email}</div>
                                        </div>
                                    </div>
                                </td>
                                <td style={{ padding: '16px 20px' }}>
                                    <span style={{ 
                                        padding: '4px 10px', 
                                        borderRadius: '12px', 
                                        fontSize: '0.8rem', 
                                        fontWeight: '600',
                                        background: `${getRoleColor(user.role)}20`,
                                        color: getRoleColor(user.role),
                                        border: `1px solid ${getRoleColor(user.role)}40`
                                    }}>
                                        {user.role}
                                    </span>
                                </td>
                                <td style={{ padding: '16px 20px' }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                                        <div style={{ width: '6px', height: '6px', borderRadius: '50%', background: user.status === 'Active' ? '#2ecc71' : '#95a5a6' }}></div>
                                        <span style={{ color: user.status === 'Active' ? '#eee' : '#bbb' }}>{user.status}</span>
                                    </div>
                                </td>
                                <td style={{ padding: '16px 20px', color: '#ccc', fontSize: '0.9rem' }}>
                                    {user.lastActive}
                                </td>
                                <td style={{ padding: '16px 20px', textAlign: 'right' }}>
                                    <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px' }}>
                                        <button style={{ background: 'none', border: 'none', color: '#ccc', cursor: 'pointer', padding: '4px' }} className="action-icon">
                                            <Edit size={16} />
                                        </button>
                                        <button style={{ background: 'none', border: 'none', color: '#e74c3c', cursor: 'pointer', padding: '4px' }} className="action-icon">
                                            <Trash2 size={16} />
                                        </button>
                                    </div>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

export default UserManagement;
