import React, { useState, useCallback } from 'react';
import Modal from './Modal';
import './UserCard.css';

const UserCard = ({ 
  user, 
  mode = 'view',
  onDeleteUser,
  onDeleteDonation 
}) => {
  const [isExpanded, setIsExpanded] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState(null);

  const formatCurrency = (value) => (Math.round(value * 100) / 100).toFixed(2);

  // Group donations and calculate totals
  const { donationsByPlatform, platformTotals } = user.donations.reduce(
    (acc, donation) => {
      const platformKey = donation.platform.toLowerCase();
      
      // Group donations
      acc.donationsByPlatform[platformKey] = [
        ...(acc.donationsByPlatform[platformKey] || []),
        donation
      ];
      
      // Calculate totals
      acc.platformTotals[platformKey] = 
        (acc.platformTotals[platformKey] || 0) + parseFloat(donation.amount);
      
      return acc;
    },
    { donationsByPlatform: {}, platformTotals: {} }
  );

  const platformNameMap = {
    paypal: 'PayPal',
    buymeacoffee: 'BuyMeACoffee',
    manual: 'Manual'
  };

  // Use useCallback to prevent unnecessary re-renders
  const handleDelete = useCallback((type, id) => {
    setDeleteTarget({ type, id });
    setShowModal(true);
  }, []);

  const handleConfirmDelete = useCallback(() => {
    if (deleteTarget?.type === 'user') {
      onDeleteUser?.();
    } else if (deleteTarget?.type === 'donation') {
      onDeleteDonation?.(deleteTarget.id);
    }
    setShowModal(false);
  }, [deleteTarget, onDeleteUser, onDeleteDonation]);

  return (
    <div className="user-card">
      <div className="border p-4 rounded-lg mb-4 shadow-md">
        {/* Header Section */}
        <div className="flex justify-between items-center">
          <div>
            <h3 className="font-bold text-xl">{user.username}</h3>
            <p className="text-gray-500">{user.email}</p>
          </div>
          
          {/* User Delete Button (Audit Mode Only) */}
          {mode === 'audit' && (
            <button 
              className="text-red-500 hover:text-red-700"
              onClick={() => handleDelete('user', user.id)}
            >
              Delete User
            </button>
          )}
        </div>

        {/* Donation Summary */}
        <div className="mt-4 donations-summary">
          {Object.entries(platformTotals).map(([platformKey, total]) => (
            <div key={platformKey} className="donation-info">
              <strong>{platformNameMap[platformKey]}:</strong> ${formatCurrency(total)}
            </div>
          ))}
        </div>

        {/* Expansion Control at Bottom */}
        <div className="mt-4 flex justify-between items-center">
          <button
            className="text-blue-500 hover:text-blue-700"
            onClick={() => setIsExpanded(!isExpanded)}
          >
            {isExpanded ? '▼' : '▶'}
          </button>
        </div>

        {/* Expanded Donation Details */}
        {isExpanded && (
          <div className="donation-details mt-4 border-t pt-4">
            {Object.entries(donationsByPlatform).map(([platformKey, donations]) => (
              <div key={platformKey} className="platform-section mb-4">
                <h4 className="font-semibold text-gray-700 mb-2">
                  {platformNameMap[platformKey]} Donations:
                </h4>
                {donations.map(donation => (
                  <div key={donation.id} className="donation-item flex justify-between items-center">
                    <span>
                      ${formatCurrency(donation.amount)} - 
                      {new Date(donation.donation_date).toLocaleDateString()}
                    </span>
                    {/* Donation Delete Button (Audit Mode Only) */}
                    {mode === 'audit' && (
                      <button
                        className="text-red-500 hover:text-red-700 text-sm"
                        onClick={() => handleDelete('donation', donation.id)}
                      >
                        Delete
                      </button>
                    )}
                  </div>
                ))}
              </div>
            ))}
          </div>
        )}
      </div>
      {/* Move modal outside the card div */}
      {showModal && (
        <Modal
          message={`Are you sure you want to delete this ${deleteTarget?.type}?`}
          onConfirm={handleConfirmDelete}
          onCancel={() => setShowModal(false)}
        />
      )}
    </div>
  );
};

export default UserCard;