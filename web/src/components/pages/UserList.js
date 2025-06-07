import React from 'react';
import { useUserManagement } from '../../hooks/useUserManagement';
import UserCard from '../UserCard';
import './UserPageCommon.css';
import SearchFilterBar from '../SearchFilterBar';

const UserList = () => {
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

  return (
    <div className="user-cards-container">
      <h2 className="text-xl font-bold mb-4">Users</h2>
      
      {/* Search/Filter controls */}
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
            showDonationDetails={false}
          />
        ))}
      </div>
    </div>
  );
};

export default UserList;