import { useCallback, useEffect, useMemo, useState } from 'react';
import { API_BASE_URL } from '../config';
import { useAuth } from '../context/AuthContext';

type AdminUser = {
  id: string;
  email: string;
  username: string;
  full_name: string | null;
  avatar_url: string | null;
  image_profile: string | null;
  points: number;
  is_active: boolean;
  is_admin: boolean;
  created_at: string;
  updated_at: string | null;
  total_reports: number;
  verified_reports: number;
};

export default function UsersPage() {
  const { session, user, isAdmin } = useAuth();
  const [users, setUsers] = useState<AdminUser[]>([]);
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);
  const [query, setQuery] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  const showToast = (message: string) => {
    setToast(message);
    setTimeout(() => setToast(null), 3000);
  };

  const loadUsers = useCallback(async () => {
    if (!session?.access_token || !isAdmin) {
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);
    try {
      const res = await fetch(`${API_BASE_URL}/users/admin?limit=200`, {
        headers: { Authorization: `Bearer ${session.access_token}` },
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        throw new Error(body.detail || `Failed to load users: ${res.status}`);
      }
      const data: AdminUser[] = await res.json();
      setUsers(data);
      setSelectedUserId((current) => current ?? data[0]?.id ?? null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load users');
    } finally {
      setIsLoading(false);
    }
  }, [isAdmin, session?.access_token]);

  useEffect(() => {
    loadUsers();
  }, [loadUsers]);

  const filteredUsers = useMemo(() => {
    const normalizedQuery = query.trim().toLowerCase();
    if (!normalizedQuery) return users;

    return users.filter((account) => {
      return (
        account.email.toLowerCase().includes(normalizedQuery) ||
        account.username.toLowerCase().includes(normalizedQuery) ||
        (account.full_name ?? '').toLowerCase().includes(normalizedQuery)
      );
    });
  }, [query, users]);

  const selectedUser = users.find((account) => account.id === selectedUserId) ?? null;

  const setUserActive = async (account: AdminUser, isActive: boolean) => {
    if (!session?.access_token) return;

    setActionLoading(account.id);
    try {
      const res = await fetch(`${API_BASE_URL}/users/admin/${account.id}/status`, {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${session.access_token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ is_active: isActive }),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        throw new Error(body.detail || `Update failed: ${res.status}`);
      }
      const updated: AdminUser = await res.json();
      setUsers((current) => current.map((item) => (item.id === updated.id ? updated : item)));
      setSelectedUserId(updated.id);
      showToast(`${updated.username} ${updated.is_active ? 'unblocked' : 'blocked'}`);
    } catch (err) {
      showToast(err instanceof Error ? err.message : 'Failed to update user');
    } finally {
      setActionLoading(null);
    }
  };

  if (!isAdmin) {
    return (
      <div className="page-shell">
        <div className="empty-state">
          <strong>Admin access required.</strong>
          <p>Only administrators can manage user restrictions.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="page-shell">
      {toast && <div className="toast">{toast}</div>}

      <div className="page-header">
        <div>
          <p className="section-label">Admin Controls</p>
          <h2>User Restrictions</h2>
          <p className="page-desc">Block or unblock mobile app users from authenticated actions.</p>
        </div>
        <button type="button" className="ghost-button" onClick={loadUsers}>
          Refresh
        </button>
      </div>

      <div className="user-admin-toolbar">
        <input
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="Search users by email, username, or name"
        />
        <span>{filteredUsers.length} users</span>
      </div>

      <div className="reports-admin-grid">
        <div className="reports-admin-list">
          {error ? (
            <div className="empty-state">
              <strong>Error loading users</strong>
              <p>{error}</p>
            </div>
          ) : isLoading ? (
            <div className="empty-state"><strong>Loading users...</strong></div>
          ) : filteredUsers.length === 0 ? (
            <div className="empty-state"><strong>No users found.</strong></div>
          ) : (
            filteredUsers.map((account) => (
              <button
                key={account.id}
                type="button"
                className={`report-admin-card${selectedUserId === account.id ? ' active' : ''}`}
                onClick={() => setSelectedUserId(account.id)}
              >
                <div className="report-admin-card-top">
                  <div className="report-admin-card-info">
                    <span className={`user-status-dot ${account.is_active ? 'active' : 'blocked'}`} />
                    <strong>{account.username}</strong>
                  </div>
                  <span className={`status-badge ${account.is_active ? 'status-verified' : 'status-rejected'}`}>
                    {account.is_active ? 'Active' : 'Blocked'}
                  </span>
                </div>
                <div className="report-admin-card-meta">
                  <span>{account.email}</span>
                  <span>{account.points} XP</span>
                  {account.is_admin && <span>Admin</span>}
                </div>
              </button>
            ))
          )}
        </div>

        <div className="reports-admin-detail">
          {selectedUser ? (
            <div className="panel" style={{ position: 'sticky', top: '80px' }}>
              <p className="section-label">Selected User</p>
              <h3 style={{ marginBottom: 16 }}>{selectedUser.username}</h3>

              <div style={{ display: 'grid', gap: 10 }}>
                <div className="detail-row">
                  <span className="detail-row-label">Status</span>
                  <span className={`status-badge ${selectedUser.is_active ? 'status-verified' : 'status-rejected'}`}>
                    {selectedUser.is_active ? 'Active' : 'Blocked'}
                  </span>
                </div>
                <div className="detail-row">
                  <span className="detail-row-label">Email</span>
                  <span>{selectedUser.email}</span>
                </div>
                <div className="detail-row">
                  <span className="detail-row-label">Full Name</span>
                  <span>{selectedUser.full_name || 'Not set'}</span>
                </div>
                <div className="detail-row">
                  <span className="detail-row-label">Role</span>
                  <span>{selectedUser.is_admin ? 'Admin' : 'User'}</span>
                </div>
                <div className="detail-row">
                  <span className="detail-row-label">Points</span>
                  <span>{selectedUser.points} XP</span>
                </div>
                <div className="detail-row">
                  <span className="detail-row-label">Joined</span>
                  <span>{new Date(selectedUser.created_at).toLocaleString('en-GB')}</span>
                </div>
              </div>

              <div className="action-buttons user-admin-actions">
                <button
                  type="button"
                  className="action-btn action-reject"
                  disabled={!selectedUser.is_active || actionLoading === selectedUser.id || selectedUser.id === user?.id}
                  onClick={() => setUserActive(selectedUser, false)}
                >
                  Block
                </button>
                <button
                  type="button"
                  className="action-btn action-verify"
                  disabled={selectedUser.is_active || actionLoading === selectedUser.id}
                  onClick={() => setUserActive(selectedUser, true)}
                >
                  Unblock
                </button>
              </div>
            </div>
          ) : (
            <div className="empty-state">
              <strong>Select a user</strong>
              <p>Choose a user account to inspect or restrict it.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
