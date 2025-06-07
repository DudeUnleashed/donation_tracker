import { useState, useEffect } from "react";
import { fetchUsers } from "../services/api";

export const useUserManagement = () => {
  const [users, setUsers] = useState([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [sortBy, setSortBy] = useState("name");
  const [filter, setFilter] = useState("all");

  useEffect(() => {
    fetchUsers().then(setUsers);
  }, []);

  const filteredUsers = users.filter(user => {
    const lowerQuery = searchQuery.toLowerCase();
    return (
      user.username.toLowerCase().includes(lowerQuery) ||
      user.email.toLowerCase().includes(lowerQuery)
    );
  });

  const platformFilteredUsers = filteredUsers.filter(user => {
    if (filter === 'all') return true;
    
    // Match platform names to your data structure
    const platformMap = {
      paypal: 'PayPal',
      bmac: 'BuyMeACoffee',
      manual: 'Manual'
    };
    
    return user.donations.some(d => d.platform === platformMap[filter]);
  });

  const sortedUsers = [...platformFilteredUsers].sort((a, b) => {
    if (sortBy === "name") return a.username.localeCompare(b.username);
    if (sortBy === "email") return a.email.localeCompare(b.email);
    if (sortBy === "donation") {
      const total = (user) => user.donations.reduce((sum, d) => sum + +d.amount, 0);
      return total(b) - total(a);
    }
    return 0;
  });

  return {
    users: sortedUsers,
    searchQuery,
    setSearchQuery,
    sortBy,
    setSortBy,
    filter,
    setFilter,
    refreshUsers: () => fetchUsers().then(setUsers)
  };
};