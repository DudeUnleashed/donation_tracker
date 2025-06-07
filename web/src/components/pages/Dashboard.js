import React, { useState, useEffect } from "react";
import { fetchUsers } from "../../services/api";
import "./Dashboard.css"; // Import the same CSS file for styling
import "./UserPageCommon.css"

const Dashboard = () => {
  const [users, setUsers] = useState([]);
  const [monthlyEarnings, setMonthlyEarnings] = useState({});
  const [monthlyPlatformEarnings, setMonthlyPlatformEarnings] = useState({
    paypal: {},
    bmac: {},
    manual: {}, // Added manual earnings here
  });
  const [expandedMonth, setExpandedMonth] = useState(null); // Track which month is expanded

  useEffect(() => {
    fetchUsers().then(fetchedUsers => {
      setUsers(fetchedUsers);
      calculateMonthlyEarnings(fetchedUsers);
      calculateMonthlyPlatformEarnings(fetchedUsers);
    });
  }, []);

  const calculateMonthlyEarnings = (users) => {
    const earningsByMonth = {};

    users.forEach(user => {
      user.donations.forEach(donation => {
        const month = donation.donation_date.substring(0, 7); // Format: "YYYY-MM"
        earningsByMonth[month] = earningsByMonth[month] || 0;
        
        const amount = parseFloat(donation.amount);
        if (!isNaN(amount)) {
          earningsByMonth[month] += amount;
        }
      });
    });

    setMonthlyEarnings(earningsByMonth);
  };

  const calculateMonthlyPlatformEarnings = (users) => {
    const earningsByMonth = { paypal: {}, bmac: {}, manual: {} }; // Manual added here

    users.forEach(user => {
      user.donations.forEach(donation => {
        const month = donation.donation_date.substring(0, 7); // Format: "YYYY-MM"
        const amount = parseFloat(donation.amount);
        if (!isNaN(amount)) {
          if (donation.platform === 'PayPal') {
            earningsByMonth.paypal[month] = earningsByMonth.paypal[month] || 0;
            earningsByMonth.paypal[month] += amount;
          } else if (donation.platform === 'BuyMeACoffee') {
            earningsByMonth.bmac[month] = earningsByMonth.bmac[month] || 0;
            earningsByMonth.bmac[month] += amount;
          } else if (donation.platform === 'Manual') {
            earningsByMonth.manual[month] = earningsByMonth.manual[month] || 0;
            earningsByMonth.manual[month] += amount;
          }
        }
      });
    });

    setMonthlyPlatformEarnings(earningsByMonth);
  };

  const handleCardClick = (month) => {
    if (expandedMonth === month) {
      setExpandedMonth(null); // If clicked again, collapse the card
    } else {
      setExpandedMonth(month); // Expand the selected month
    }
  };

  const renderMonthlyEarnings = () => {
    // Sort the months in descending order (most recent month first)
    const sortedMonths = Object.keys(monthlyEarnings).sort((a, b) => b.localeCompare(a));

    return sortedMonths.map(month => {
      const totalEarnings = monthlyEarnings[month];
      const paypalEarnings = monthlyPlatformEarnings.paypal[month] || 0;
      const bmacEarnings = monthlyPlatformEarnings.bmac[month] || 0;
      const manualEarnings = monthlyPlatformEarnings.manual[month] || 0; // Added manual earnings here
      const totalPlatformEarnings = paypalEarnings + bmacEarnings + manualEarnings;

      const paypalPercentage = totalPlatformEarnings > 0 ? (paypalEarnings / totalPlatformEarnings) * 100 : 0;
      const bmacPercentage = totalPlatformEarnings > 0 ? (bmacEarnings / totalPlatformEarnings) * 100 : 0;
      const manualPercentage = totalPlatformEarnings > 0 ? (manualEarnings / totalPlatformEarnings) * 100 : 0; // Manual percentage

      return (
        <div key={month} className="user-card" onClick={() => handleCardClick(month)}>
          <div className="card-content">
            <strong>{month}:</strong> {totalEarnings.toFixed(2)} USD
            {expandedMonth === month && (
              <div className="platform-breakdown">
                <div>
                  <strong>PayPal:</strong> {paypalEarnings.toFixed(2)} USD ({paypalPercentage.toFixed(2)}%)
                </div>
                <div>
                  <strong>BuyMeACoffee:</strong> {bmacEarnings.toFixed(2)} USD ({bmacPercentage.toFixed(2)}%)
                </div>
                <div>
                  <strong>Manual:</strong> {manualEarnings.toFixed(2)} USD ({manualPercentage.toFixed(2)}%)
                </div>
              </div>
            )}
          </div>
        </div>
      );
    });
  };

  const totalEarnings = Object.values(monthlyEarnings).reduce((acc, curr) => acc + curr, 0);

  return (
    <div className="user-cards-container">
    <h2 className="text-xl font-bold mb-4">Dashboard</h2>

    <div className="mb-4">
      <h3>Total Earnings: {totalEarnings.toFixed(2)} USD</h3>
    </div>

    <div className="monthly-earnings-container">
      <h3>Monthly Earnings Breakdown</h3>
      <div className="grid">
        {renderMonthlyEarnings()}
      </div>
    </div>
  </div>
  );
};

export default Dashboard;
