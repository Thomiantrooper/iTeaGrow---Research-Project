import React from 'react';
import { BrowserRouter as Router } from 'react-router-dom';
import { GoogleOAuthProvider } from '@react-oauth/google';
import { AuthProvider } from './context/AuthContext';
import { HealthProvider, HealthContext } from './context/HealthContext';
import AppRoutes from './routes/AppRoutes';
import ErrorBoundary from './components/common/ErrorBoundary';

const GOOGLE_CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID || '422600401949-2icliet7cotors3q8equqi2ahcncb7ts.apps.googleusercontent.com';

function App() {
  return (
    <GoogleOAuthProvider clientId={GOOGLE_CLIENT_ID}>
    <Router>
      <AuthProvider>
        <HealthProvider>
          <HealthContext.Consumer>
            {({ triggerAlert }) => (
              <ErrorBoundary triggerAlert={triggerAlert}>
                <AppRoutes />
              </ErrorBoundary>
            )}
          </HealthContext.Consumer>
        </HealthProvider>
      </AuthProvider>
    </Router>
    </GoogleOAuthProvider>
  );
}

export default App;
