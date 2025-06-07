import axios from 'axios';

const API_BASE_URL = 'http://localhost:3001/admin';

const adminApi = axios.create({
  baseURL: API_BASE_URL
});

adminApi.interceptors.request.use((config) => {
  const token = localStorage.getItem('adminToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const adminLogin = async (credentials) => {
  try {
    const response = await adminApi.post('/auth/login', credentials);
    return response.data;
  } catch (error) {
    throw error;
  }
};

export default adminApi;
