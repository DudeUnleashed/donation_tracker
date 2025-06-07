// App.js
import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './contexts/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import Navbar from './components/Navbar';
import Login from './components/pages/Login';
import Home from './components/pages/Home';
import Dashboard from './components/pages/Dashboard';
import UserList from './components/pages/UserList';
import UserAudit from './components/pages/UserAudit';
import AuditLogs from './components/pages/AuditLogs';
import ManualEntryPage from './components/pages/ManualEntry';
import CsvUploadPage from './components/pages/CsvUpload';
import { ToastContainer } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';
import './App.css'

function App() {
  return (
    <Router>
      <AuthProvider>
        <ToastContainer position="top-right" autoClose={3000} />
        <Navbar />
        <div className="page-content">
          <Routes>
            {/* Public routes */}
            <Route path="/login" element={<Login />} />
            
            {/* Protected routes */}
            <Route path="/" element={
              <ProtectedRoute>
                <Home />
              </ProtectedRoute>
            } />
            <Route path="/dashboard" element={
              <ProtectedRoute>
                <Dashboard />
              </ProtectedRoute>
            } />
            <Route path="/users" element={
              <ProtectedRoute>
                <UserList />
              </ProtectedRoute>
            } />
            
            {/* Admin-only routes */}
            <Route path="/audit" element={
              <ProtectedRoute requireAdmin={true}>
                <UserAudit />
              </ProtectedRoute>
            } />
            <Route path="/audit-logs" element={
              <ProtectedRoute requireAdmin={true}>
                <AuditLogs />
              </ProtectedRoute>
            } />
            <Route path="/manual-entry" element={
              <ProtectedRoute requireAdmin={true}>
                <ManualEntryPage />
              </ProtectedRoute>
            } />
            <Route path="/csv-upload" element={
              <ProtectedRoute requireAdmin={true}>
                <CsvUploadPage />
              </ProtectedRoute>
            } />
            
            {/* Catch all - redirect to home */}
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </div>
      </AuthProvider>
    </Router>
  );
}

export default App;