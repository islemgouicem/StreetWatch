import { NavLink } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function Navbar() {
  const { user, isAdmin, signOut } = useAuth();

  return (
    <nav className="navbar">
      <div className="navbar-inner">
        {/* Brand */}
        <NavLink to="/" className="navbar-brand">
          <span className="navbar-icon">🛣️</span>
          <span className="navbar-name">StreetWatch</span>
          <span className="navbar-tag">Dashboard</span>
        </NavLink>

        {/* Links */}
        <div className="navbar-links">
          <NavLink
            to="/"
            end
            className={({ isActive }) => `nav-link${isActive ? ' active' : ''}`}
          >
            🗺️ Live Map
          </NavLink>
          <NavLink
            to="/reports"
            className={({ isActive }) => `nav-link${isActive ? ' active' : ''}`}
          >
            📋 Reports
          </NavLink>
          <NavLink
            to="/leaderboard"
            className={({ isActive }) => `nav-link${isActive ? ' active' : ''}`}
          >
            🏆 Leaderboard
          </NavLink>
        </div>

        {/* User */}
        <div className="navbar-user">
          {isAdmin && <span className="admin-badge">Admin</span>}
          <span className="navbar-email">{user?.email}</span>
          <button type="button" className="signout-btn" onClick={signOut}>
            Sign out
          </button>
        </div>
      </div>
    </nav>
  );
}
