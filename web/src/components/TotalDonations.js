import React from 'react';

const TotalDonations = ({ totalDonations }) => {
  const validTotalDonations = Number(totalDonations) || 0;
  const formattedTotal = validTotalDonations.toFixed(2);
  return (
    <div className="mb-4">
      <strong>Total Donations: </strong>
      ${formattedTotal} {/* Display the total in 2 decimal format */}
    </div>
  );
};

export default TotalDonations;
