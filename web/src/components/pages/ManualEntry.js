import React, { useState, useEffect } from "react";
import { fetchUsers, addManualEntry, createUser } from "../../services/api";
import './ManualEntry.css';

const ManualEntryPage = () => {
  const [userId, setUserId] = useState("");
  const [amount, setAmount] = useState("");
  const [date, setDate] = useState("");
  const [isNewUser, setIsNewUser] = useState(false);
  const [newUser, setNewUser] = useState({ username: "", email: "" });
  const [users, setUsers] = useState([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [filteredUsers, setFilteredUsers] = useState([]);
  const [selectedUser, setSelectedUser] = useState(null);
  const [errors, setErrors] = useState({ username: "", email: "" });
  const [isSubmitting, setIsSubmitting] = useState(false); // Track if form is submitting

  useEffect(() => {
    // Fetch all users when the component mounts
    fetchUsers().then(setUsers);
  }, []);

  useEffect(() => {
    // Filter users based on the search query
    if (searchQuery) {
      const filtered = users.filter(user =>
        user.username.toLowerCase().includes(searchQuery.toLowerCase()) ||
        user.email.toLowerCase().includes(searchQuery.toLowerCase())
      );
      setFilteredUsers(filtered);
    } else {
      setFilteredUsers([]);
    }
  }, [searchQuery, users]);

  const handleSubmit = async (e) => {
    e.preventDefault();
  
    let finalUserId = userId;
  
    if (isNewUser) {
      // Create a new user if this is a new user
      const createdUser = await createUser(newUser);
      if (createdUser) {
        finalUserId = createdUser.id;  // Set the userId to the created user's ID
      }
    } else if (selectedUser) {
      // Use the selected user's ID
      finalUserId = selectedUser.id;
    }
  
    // Prepare donation data and send to backend
    const donationData = {
      user_id: finalUserId,
      amount: parseFloat(amount),
      donation_date: date,
    };
  
    try {
      const savedDonation = await addManualEntry(donationData);
    } catch (err) {
    }
  };
  

  const handleUserSelect = (user) => {
    setSelectedUser(user);
    setUserId(user.id); // Immediately set userId when an existing user is selected
    setSearchQuery(""); // Clear search query once user is selected
    setFilteredUsers([]); // Hide the dropdown
  };

  return (
    <div className="manual-entry-container">
      <h2 className="manual-entry-header">Manual Entry</h2>
      <form className="manual-entry-form" onSubmit={handleSubmit}>
        <div className="user-selection">
          <label className="checkbox-label">
            <input
              type="checkbox"
              checked={isNewUser}
              onChange={() => setIsNewUser(!isNewUser)}
              className="checkbox-input"
            />
            <span>Create new user</span>
          </label>
        </div>

        {!isNewUser ? (
          <div className="existing-user-select user-dropdown-container">
            <label>Select Existing User</label>
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search users"
              className="input-field search-input"
            />
            {filteredUsers.length > 0 && (
              <ul className="user-dropdown">
                {filteredUsers.map((user) => (
                  <li
                    key={user.id}
                    onClick={() => handleUserSelect(user)}
                    className="user-dropdown-item"
                  >
                    {user.username} ({user.email})
                  </li>
                ))}
              </ul>
            )}
            {selectedUser && (
              <div className="selected-user">
                <p>Selected User: {selectedUser.username} ({selectedUser.email})</p>
              </div>
            )}
          </div>
        ) : (
          <div className="new-user-inputs">
            <label>Username</label>
            <input
              type="text"
              value={newUser.username}
              onChange={(e) => setNewUser({ ...newUser, username: e.target.value })}
              className="input-field"
              required
            />
            {errors.username && <div className="error">{errors.username}</div>}
            <label>Email</label>
            <input
              type="email"
              value={newUser.email}
              onChange={(e) => setNewUser({ ...newUser, email: e.target.value })}
              className="input-field"
              required
            />
            {errors.email && <div className="error">{errors.email}</div>}
          </div>
        )}

        <div className="amount-date-inputs">
          <label>Amount</label>
          <input
            type="number"
            step="0.01"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            className="input-field"
            required
          />
        </div>
        <div className="amount-date-inputs">
          <label>Date</label>
          <input
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            className="input-field"
            required
          />
        </div>

        <button type="submit" className="submit-btn" disabled={isSubmitting}>
          {isSubmitting ? "Submitting..." : "Submit"}
        </button>
      </form>
    </div>
  );
};

export default ManualEntryPage;
