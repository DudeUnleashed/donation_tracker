import React from 'react';
import { useUserManagement } from '../../hooks/useUserManagement';
import UserCard from '../UserCard';
import { deleteUser, deleteDonation } from '../../services/api';
import SearchFilterBar from '../SearchFilterBar';
import './UserPageCommon.css';
import { toast } from 'react-toastify';

const UserAudit = () => {

  const { 
    users,
    searchQuery, 
    setSearchQuery,
    filter,
    setFilter,
    sortBy,
    setSortBy,
    refreshUsers 
  } = useUserManagement();

  const handleDeleteUser = async (userId) => {
    try {
      await deleteUser(userId);
      await refreshUsers();
    } catch (error) {
      toast.error('Failed to delete user');
      console.error("Delete error:", error);
    }
  };

  const handleDeleteDonation = async (donationId) => {
    try {
      await deleteDonation(donationId);
      await refreshUsers();
    } catch (error) {
      toast.error('Failed to delete donation');
      console.error("Delete error:", error);
    }
  };

  return (
    <div className="user-cards-container audit-page-container">
      <h2 className="text-xl font-bold mb-4">Audit Page</h2>
      
      <SearchFilterBar
        searchQuery={searchQuery}
        onSearchChange={setSearchQuery}
        filter={filter}
        onFilterChange={setFilter}
        sortBy={sortBy}
        onSortChange={setSortBy}
        onRefresh={refreshUsers}
      />

      <div className="grid">
        {users.map(user => (
          <UserCard
          key={user.id}
          user={user}
          mode="audit"
          onDeleteUser={() => handleDeleteUser(user.id)}
          onDeleteDonation={(donationId) => handleDeleteDonation(donationId)}
        />
        ))}
      </div>
    </div>
  );
};

export default UserAudit;