// contexts/AuthContext.js
import React, { createContext, useContext, useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  // Check for existing token and user on mount
  useEffect(() => {
    const token = localStorage.getItem('token');
    const storedUser = localStorage.getItem('user');
    
    if (token && storedUser) {
      try {
        const userData = JSON.parse(storedUser);
        // Ensure role is correctly set
        if (!userData.role) {
          userData.role = 'viewer'; // Default role if none is set
        }
        setUser(userData);
      } catch (e) {
        // Handle invalid stored user data
        localStorage.removeItem('user');
        localStorage.removeItem('token');
      }
    }
    
    setLoading(false);
  }, []);

  const login = (userData, token) => {
    // Make sure role is preserved from backend data or defaulted to 'viewer'
    const userWithRole = {
      ...userData,
      // If no role is provided in userData, default to 'viewer'
      role: userData.role || 'viewer'
    };
    
    // Store in state and localStorage
    setUser(userWithRole);
    localStorage.setItem('token', token);
    localStorage.setItem('user', JSON.stringify(userWithRole));
    
    console.log('User logged in with role:', userWithRole.role);
  };

  const logout = () => {
    setUser(null);
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    navigate('/');
  };

  return (
    <AuthContext.Provider value={{ user, login, logout, loading }}>
      {!loading && children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);