import axios from 'axios';
import { toast } from 'react-toastify';
import './toastify.css';

const API_BASE_URL = 'http://localhost:3001/api';

const api = axios.create({
    baseURL: API_BASE_URL
});

// Add auth token to requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const fetchUsers = async () => {
    try {
        const response = await api.get('/users');
        return response.data;
    } catch (error) {
        console.error('Error fetching users:', error);
        return [];
    }
};

export const fetchDonations = async () => {
    try {
        const response = await api.get('/donations');
        return response.data;
    } catch (error) {
        console.error('Error fetching donations:', error);
        return [];
    }
}

export const searchUsers = async (searchQuery) => {
    try {
        const response = await api.get(`/users/search?query=${searchQuery}`);
        return response.data;
    } catch (error) {
        console.error('Error searching users:', error);
        return [];
    }
};

export const fetchLogs = async () => {
  try {
    const response = await api.get('/audit_logs');
    return response.data;
  } catch (error) {
    console.error('Error fetching audit log: ', error);
    return [];
  }
}

export const createUser = async (newUser) => {
    try {
        const response = await api.post('/users', {
            username: newUser.username,
            email: newUser.email});
        toast.success('Created User');
        return response.data;
    } catch (error) {
        toast.error('Error creating user');
        return error;
    }
};

export const addManualEntry = async (donationData) => {
    try {
      const response = await api.post("/donations", donationData);
      toast.success('Created Donation!')
      return response.data;
    } catch (error) {
      toast.error('Failed to create manual entry')
      throw error;
    }
};

export const deleteUser = async (userId) => {
    try {
      const response = await api.delete(`/users/${userId}`);
      toast.success('Deleted User')
      return response.data;
    } catch (error) {
      toast.error('Failed to delete user');
      throw error;
    }
};

export const deleteDonation = async (donationId) => {
    try {
      const response = await api.delete(`/donations/${donationId}`);
      toast.success('Deleted Donation')
      return response.data;
    } catch (error) {
      toast.error('Failed to delete donation');
      throw error;
    }
};

export const login = async (credentials) => {
  try {
    const response = await api.post('/auth/login', credentials);
    return response.data;
  } catch (error) {
    throw error;
  }
};

export const uploadCsv = async (formData) => {
  try {
    const response = await api.post('/csv_upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data;
  } catch (error) {
    throw error;
  }
};

export default api;
