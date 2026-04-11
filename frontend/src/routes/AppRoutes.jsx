import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import HomePage from '../pages/HomePage';
import AboutPage from '../pages/AboutPage';
import ContactPage from '../pages/ContactPage';
import HistoryPage from '../pages/HistoryPage';
import ProfilePage from '../pages/ProfilePage';
import AdminLayout from '../layouts/AdminLayout';
import AdminDashboard from '../pages/admin/Dashboard';
import UserManagement from '../pages/admin/UserManagement';
import SystemHealth from '../pages/admin/SystemHealth';
import IssuesBugs from '../pages/admin/IssuesBugs';
import MarketAuction from '../pages/admin/MarketAuction';
import Devices from '../pages/admin/Devices';
import DataCollection from '../pages/admin/DataCollection';
import Feedback from '../pages/admin/Feedback';
import LoginPage from '../pages/LoginPage';
import ProtectedRoute from '../components/ProtectedRoute';
import PrivacyPolicyPage from '../pages/PrivacyPolicyPage';

const AppRoutes = () => {
  return (
    <Routes>
      {/* Public Routes */}
      <Route path="/" element={<MainLayout />}>
        <Route index element={<HomePage />} />
        <Route path="about" element={<AboutPage />} />
        <Route path="contact" element={<ContactPage />} />
        <Route path="history" element={<HistoryPage />} />
        <Route path="profile" element={<ProfilePage />} />
        <Route path="privacy-policy" element={<PrivacyPolicyPage />} />
      </Route>
      
      <Route path="/login" element={<LoginPage />} />

      {/* Redirect legacy dashboard to admin */}
      <Route path="/dashboard" element={<Navigate to="/admin/dashboard" replace />} />
      
      {/* Protected Admin Routes */}
      <Route element={<ProtectedRoute />}>
        <Route path="/admin" element={<AdminLayout />}>
          <Route index element={<Navigate to="/admin/dashboard" replace />} />
          <Route path="dashboard" element={<AdminDashboard />} />
          <Route path="users" element={<UserManagement />} />
          <Route path="devices" element={<Devices />} />
          <Route path="data" element={<DataCollection />} />
          <Route path="market-auction" element={<MarketAuction />} />
          <Route path="health" element={<SystemHealth />} />
          <Route path="issues" element={<IssuesBugs />} />
          <Route path="feedback" element={<Feedback />} />
        </Route>
      </Route>
    </Routes>
  );
};

export default AppRoutes;
