import React from 'react';
import { BrowserRouter as Router } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { HealthProvider } from './context/HealthContext';
import AppRoutes from './routes/AppRoutes';

function App() {
  return (
    <Router>
      <AuthProvider>
        <HealthProvider>
          <AppRoutes />
        </HealthProvider>
      </AuthProvider>
    </Router>
  );
}

export default App;
