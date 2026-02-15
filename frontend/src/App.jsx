import React from 'react';
import { BrowserRouter as Router } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { HealthProvider, HealthContext } from './context/HealthContext';
import AppRoutes from './routes/AppRoutes';
import ErrorBoundary from './components/common/ErrorBoundary';

function App() {
  return (
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
  );
}

export default App;
