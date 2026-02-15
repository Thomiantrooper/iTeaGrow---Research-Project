import React from 'react';
import { Construction } from 'lucide-react';

const DummyPage = ({ title, description }) => {
    return (
        <div className="dashboard-container" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '60vh', textAlign: 'center' }}>
            <div style={{ 
                background: 'rgba(255, 255, 255, 0.05)', 
                padding: '40px', 
                borderRadius: '20px', 
                border: '1px solid rgba(255, 255, 255, 0.1)',
                backdropFilter: 'blur(10px)',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: '20px',
                maxWidth: '500px'
            }}>
                <div style={{ 
                    padding: '20px', 
                    borderRadius: '50%', 
                    background: 'rgba(46, 204, 113, 0.1)',
                    color: '#2ecc71',
                    marginBottom: '10px'
                }}>
                    <Construction size={48} />
                </div>
                <h2 style={{ color: 'white', fontSize: '1.8rem', margin: 0 }}>{title}</h2>
                <p style={{ color: '#ccc', fontSize: '1rem', lineHeight: '1.6' }}>
                    {description}
                </p>
                <div style={{ 
                    marginTop: '20px', 
                    padding: '10px 20px', 
                    background: 'rgba(243, 156, 18, 0.1)', 
                    border: '1px solid rgba(243, 156, 18, 0.2)', 
                    borderRadius: '8px', 
                    color: '#f39c12',
                    fontSize: '0.9rem'
                }}>
                    <strong>Note:</strong> This section contains dummy data or is currently under development.
                </div>
            </div>
        </div>
    );
};

export default DummyPage;
