import React from 'react';
import { AlertTriangle, RefreshCw, Home } from 'lucide-react';

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null, errorInfo: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true };
  }

  componentDidCatch(error, errorInfo) {
    this.setState({ error, errorInfo });
    
    // Auto-log the error to our administration dashboard
    if (this.props.triggerAlert) {
      this.props.triggerAlert('Frontend UI', [
        `CRASH: ${error.toString()}`,
        `Location: ${window.location.pathname}`,
        'System: Automatic Frontend Error Boundary Catch'
      ]);
    }
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{
          height: '100vh',
          width: '100vw',
          background: 'linear-gradient(135deg, #0f170f 0%, #050505 100%)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '20px',
          color: '#fff',
          fontFamily: 'Poppins, sans-serif'
        }}>
          <div style={{
            maxWidth: '600px',
            width: '100%',
            background: 'rgba(255, 255, 255, 0.03)',
            backdropFilter: 'blur(20px)',
            border: '1px solid rgba(255, 255, 255, 0.1)',
            borderRadius: '24px',
            padding: '40px',
            textAlign: 'center',
            boxShadow: '0 20px 50px rgba(0,0,0,0.5)'
          }}>
            <div style={{
              width: '80px',
              height: '80px',
              background: 'rgba(231, 76, 60, 0.1)',
              borderRadius: '20px',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              margin: '0 auto 24px',
              color: '#e74c3c'
            }}>
              <AlertTriangle size={40} />
            </div>

            <h1 style={{ fontSize: '2rem', fontWeight: '800', marginBottom: '12px' }}>
              Something Went Wrong
            </h1>
            
            <p style={{ color: 'rgba(255, 255, 255, 0.6)', lineHeight: '1.6', marginBottom: '32px' }}>
              A frontend exception was caught. The error has been automatically logged for the administrator to review and resolve.
            </p>

            <div style={{
              background: 'rgba(0,0,0,0.3)',
              borderRadius: '12px',
              padding: '15px',
              marginBottom: '32px',
              textAlign: 'left',
              fontSize: '0.85rem',
              fontFamily: 'monospace',
              color: '#e74c3c',
              border: '1px solid rgba(231, 76, 60, 0.2)',
              overflow: 'hidden',
              textOverflow: 'ellipsis'
            }}>
              {this.state.error && this.state.error.toString()}
            </div>

            <div style={{ display: 'flex', gap: '15px', justifyContent: 'center' }}>
              <button 
                onClick={() => window.location.reload()}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  background: '#2ecc71',
                  color: '#fff',
                  border: 'none',
                  padding: '12px 24px',
                  borderRadius: '12px',
                  fontWeight: '700',
                  cursor: 'pointer',
                  transition: 'all 0.3s'
                }}
              >
                <RefreshCw size={18} /> RELOAD PAGE
              </button>
              
              <button 
                onClick={() => window.location.href = '/'}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '8px',
                  background: 'rgba(255,255,255,0.05)',
                  color: '#fff',
                  border: '1px solid rgba(255,255,255,0.1)',
                  padding: '12px 24px',
                  borderRadius: '12px',
                  fontWeight: '700',
                  cursor: 'pointer'
                }}
              >
                <Home size={18} /> GO HOME
              </button>
            </div>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
