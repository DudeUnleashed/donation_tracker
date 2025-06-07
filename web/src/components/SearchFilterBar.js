export const SearchFilterBar = ({
  searchQuery,
  onSearchChange,
  filter,
  onFilterChange,
  sortBy,
  onSortChange,
  onRefresh
}) => (
  <div className="search-filter-container">
    <input
      type="text"
      value={searchQuery}
      onChange={e => onSearchChange(e.target.value)}
      placeholder="Search by name or email"
      className="search-input"
    />

    <div className="filter-buttons">
      {['all', 'paypal', 'bmac', 'manual'].map((platform) => (
        <button
          key={platform}
          onClick={() => onFilterChange(platform)}
          className={`filter-button ${filter === platform ? "active" : ""}`}
        >
          {platform.charAt(0).toUpperCase() + platform.slice(1)}
        </button>
      ))}
      <button onClick={onRefresh}>Refresh</button>
    </div>

    <select value={sortBy} onChange={e => onSortChange(e.target.value)}>
      <option value="name">Name</option>
      <option value="email">Email</option>
      <option value="donation">Donation Amount</option>
    </select>
  </div>
);

export default SearchFilterBar;