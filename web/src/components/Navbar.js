import { Link, useLocation } from "react-router-dom";
import { useAuth } from "../contexts/AuthContext";
import './Navbar.css';

const Navbar = () => {
  const { user, logout } = useAuth();
  const location = useLocation();

  const isLoggedIn = user !== null;
  const isAdmin = user?.role === 'admin' || user?.isAdmin === true;

  const isActive = (path) => location.pathname === path;

  return (
    <nav className="navbar">
      <div className="navbar-inner">
        {/* Centered links */}
        <div className="nav-links">
          
          {!isLoggedIn && (
            <h4>Hi there</h4>
          )}

          {isLoggedIn && !isAdmin && (
            <>
            <Link to="/" className={`nav-link ${isActive("/") ? "active" : ""}`}>Home</Link>
            <Link to="/dashboard" className={`nav-link ${isActive("/dashboard") ? "active" : ""}`}>Dashboard</Link>
            <Link to="/users" className={`nav-link ${isActive("/users") ? "active" : ""}`}>Users</Link>
            </>
          )}

          {isAdmin && (
            <>
              <Link to="/" className={`nav-link ${isActive("/") ? "active" : ""}`}>Home</Link>
              <Link to="/dashboard" className={`nav-link ${isActive("/dashboard") ? "active" : ""}`}>Dashboard</Link>
              <Link to="/users" className={`nav-link ${isActive("/users") ? "active" : ""}`}>Users</Link>
              <Link to="/audit" className={`nav-link ${isActive("/audit") ? "active" : ""}`}>Audit</Link>
              <Link to="/audit-logs" className={`nav-link ${isActive("/audit-logs") ? "active" : ""}`}>Audit Logs</Link>
              <Link to="/csv-upload" className={`nav-link ${isActive("/csv-upload") ? "active" : ""}`}>CSV Upload</Link>
              <Link to="/manual-entry" className={`nav-link ${isActive("/manual-entry") ? "active" : ""}`}>Manual Entry</Link>
            </>
          )}
        </div>

        {/* Right-aligned auth links */}
        <div className="auth-links">
          {!isLoggedIn ? (
            <>
              <Link to="/login" className={`nav-link ${isActive("/login") ? "active" : ""}`}>Login</Link>
            </>
          ) : (
            <button className="nav-link logout-btn" onClick={logout}>Logout</button>
          )}
        </div>
      </div>
    </nav>
  );
};

export default Navbar;
