import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { uploadCsv } from '../../services/api';

const CsvUploadPage = () => {
  const [file, setFile] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [message, setMessage] = useState('');
  const [provider, setProvider] = useState('generic');
  const navigate = useNavigate();

  const handleFileChange = (e) => {
    setFile(e.target.files[0]);
    setMessage('');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!file) {
      setMessage('Please select a CSV file to upload.');
      return;
    }

    const formData = new FormData();
    formData.append('csv_file', file);
    formData.append('provider', provider);

    try {
      setUploading(true);
      const response = await uploadCsv(formData);
      setMessage('Upload successful!');
      setFile(null);
    } catch (error) {
      setMessage(error.response?.data?.error || 'Upload failed. Please try again.');
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="user-cards-container">
      <h2>CSV Upload</h2>
      <form onSubmit={handleSubmit} style={{ marginBottom: '1rem' }}>
        <div className="search-filter-container">
          <input
            type="file"
            accept=".csv"
            onChange={handleFileChange}
            className="search-input"
          />
          <select 
            value={provider} 
            onChange={(e) => setProvider(e.target.value)}
            className="search-input"
          >
            <option value="generic">Generic</option>
            <option value="paypal">PayPal</option>
            <option value="stripe">Stripe</option>
            <option value="square">Square</option>
          </select>
          <button
            type="submit"
            className="filter-button"
            disabled={uploading}
          >
            {uploading ? 'Uploading...' : 'Upload CSV'}
          </button>
        </div>
      </form>
      {message && <p>{message}</p>}
    </div>
  );
};

export default CsvUploadPage;
