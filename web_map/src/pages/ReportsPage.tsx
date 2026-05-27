import { useEffect, useState, useCallback } from 'react';
import { useAuth } from '../context/AuthContext';
import type { Report, ReportStatus } from '../types';
import { damageTypeLabel, severityLabel, statusLabel } from '../types';

const BACKEND_URL = 'http://localhost:8000/api/v1';

const STATUS_FILTERS: { label: string; value: ReportStatus | 'all' }[] = [
  { label: 'All', value: 'all' },
  { label: '⏳ Pending', value: 'pending' },
  { label: '🔍 Under Review', value: 'under_review' as ReportStatus },
  { label: '✅ Verified', value: 'verified' },
  { label: '🔧 Resolved', value: 'resolved' },
  { label: '❌ Rejected', value: 'rejected' },
];

type ActionType = 'verify' | 'reject' | 'resolve';

export default function ReportsPage() {
  const { session, isAdmin } = useAuth();
  const [reports, setReports] = useState<Report[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<ReportStatus | 'all'>('all');
  const [actionLoading, setActionLoading] = useState<string | null>(null); // reportId being acted on
  const [selectedReport, setSelectedReport] = useState<Report | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 3000);
  };

  const fetchReports = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const params = statusFilter !== 'all' ? `?status=${statusFilter}&limit=100` : '?limit=100';
      const res = await fetch(`${BACKEND_URL}/reports${params}`);
      if (!res.ok) throw new Error(`Failed: ${res.status}`);
      const data: Report[] = await res.json();
      setReports(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load reports');
    } finally {
      setIsLoading(false);
    }
  }, [statusFilter]);

  useEffect(() => {
    fetchReports();
  }, [fetchReports]);

  const doAction = async (reportId: string, action: ActionType) => {
    if (!session?.access_token) return;
    setActionLoading(reportId);
    try {
      const res = await fetch(`${BACKEND_URL}/reports/${reportId}/${action}`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${session.access_token}` },
      });
      if (!res.ok) {
        const errData = await res.json().catch(() => ({}));
        throw new Error(errData.detail || `Action failed: ${res.status}`);
      }
      const updated: Report = await res.json();
      setReports((prev) => prev.map((r) => (r.id === reportId ? updated : r)));
      if (selectedReport?.id === reportId) setSelectedReport(updated);
      showToast(`Report ${action === 'verify' ? 'verified ✅' : action === 'reject' ? 'rejected ❌' : 'resolved 🔧'}`);
    } catch (err) {
      showToast(`⚠️ ${err instanceof Error ? err.message : 'Action failed'}`);
    } finally {
      setActionLoading(null);
    }
  };

  const getActionButtons = (report: Report) => {
    if (!isAdmin) return null;
    const loading = actionLoading === report.id;
    return (
      <div className="action-buttons">
        {report.status !== 'verified' && report.status !== 'resolved' && (
          <button
            type="button"
            className="action-btn action-verify"
            disabled={loading}
            onClick={(e) => { e.stopPropagation(); doAction(report.id, 'verify'); }}
          >
            ✅ Verify
          </button>
        )}
        {report.status !== 'resolved' && (
          <button
            type="button"
            className="action-btn action-resolve"
            disabled={loading}
            onClick={(e) => { e.stopPropagation(); doAction(report.id, 'resolve'); }}
          >
            🔧 Resolve
          </button>
        )}
        {report.status !== 'rejected' && (
          <button
            type="button"
            className="action-btn action-reject"
            disabled={loading}
            onClick={(e) => { e.stopPropagation(); doAction(report.id, 'reject'); }}
          >
            ❌ Reject
          </button>
        )}
      </div>
    );
  };

  return (
    <div className="page-shell">
      {/* Toast */}
      {toast && <div className="toast">{toast}</div>}

      {/* Page header */}
      <div className="page-header">
        <div>
          <p className="section-label">Moderation Center</p>
          <h2>All Reports</h2>
          <p className="page-desc">
            Review, verify, resolve or reject reports submitted by mobile app users.
            {!isAdmin && ' Log in as an admin to take moderation actions.'}
          </p>
        </div>
        <button type="button" className="ghost-button" onClick={fetchReports}>
          ↺ Refresh
        </button>
      </div>

      {/* Status filter tabs */}
      <div className="tab-bar">
        {STATUS_FILTERS.map((f) => (
          <button
            key={f.value}
            type="button"
            className={`tab-btn${statusFilter === f.value ? ' active' : ''}`}
            onClick={() => setStatusFilter(f.value)}
          >
            {f.label}
            {f.value !== 'all' && (
              <span className="tab-count">
                {reports.filter((r) => r.status === f.value).length}
              </span>
            )}
          </button>
        ))}
      </div>

      <div className="reports-admin-grid">
        {/* Report list */}
        <div className="reports-admin-list">
          {error ? (
            <div className="empty-state">
              <strong>Error loading reports</strong>
              <p>{error}</p>
            </div>
          ) : isLoading ? (
            <div className="empty-state"><strong>Loading reports…</strong></div>
          ) : reports.length === 0 ? (
            <div className="empty-state"><strong>No reports found.</strong></div>
          ) : (
            reports.map((report) => (
              <button
                key={report.id}
                type="button"
                className={`report-admin-card${selectedReport?.id === report.id ? ' active' : ''}`}
                onClick={() => setSelectedReport(report)}
              >
                <div className="report-admin-card-top">
                  <div className="report-admin-card-info">
                    <span className={`severity-pill severity-${report.severity}`}>
                      {severityLabel[report.severity]}
                    </span>
                    <strong>{damageTypeLabel[report.damage_type]}</strong>
                  </div>
                  <span className={`status-badge status-${report.status}`}>
                    {statusLabel[report.status]}
                  </span>
                </div>

                <div className="report-admin-card-meta">
                  <span>👤 {report.user_name}{report.user_points != null ? ` · ${report.user_points} XP` : ''}</span>
                  <span>📍 {report.latitude.toFixed(4)}, {report.longitude.toFixed(4)}</span>
                  <span>🗓 {new Date(report.created_at).toLocaleDateString('en-GB')}</span>
                  <span>👍 {report.upvotes} · 👎 {report.downvotes}</span>
                </div>

                {report.description && (
                  <p className="report-admin-card-desc">{report.description}</p>
                )}

                {getActionButtons(report)}
              </button>
            ))
          )}
        </div>

        {/* Detail panel */}
        <div className="reports-admin-detail">
          {selectedReport ? (
            <div className="panel" style={{ position: 'sticky', top: '80px' }}>
              <p className="section-label">Report Detail</p>
              <h3 style={{ marginBottom: 16 }}>{damageTypeLabel[selectedReport.damage_type]}</h3>

              {selectedReport.image_url && (
                <img
                  src={selectedReport.image_url}
                  alt=""
                  className="admin-detail-img"
                />
              )}

              <div style={{ display: 'grid', gap: 10, marginTop: 16 }}>
                <div className="detail-row">
                  <span className="detail-row-label">Status</span>
                  <span className={`status-badge status-${selectedReport.status}`}>
                    {statusLabel[selectedReport.status]}
                  </span>
                </div>
                <div className="detail-row">
                  <span className="detail-row-label">Severity</span>
                  <span className={`severity-pill severity-${selectedReport.severity}`}>
                    {severityLabel[selectedReport.severity]}
                  </span>
                </div>
                <div className="detail-row">
                  <span className="detail-row-label">Reporter</span>
                  <span>{selectedReport.user_name}</span>
                </div>
                {selectedReport.user_points != null && (
                  <div className="detail-row">
                    <span className="detail-row-label">Reporter XP</span>
                    <span>⭐ {selectedReport.user_points}</span>
                  </div>
                )}
                <div className="detail-row">
                  <span className="detail-row-label">Coordinates</span>
                  <span>{selectedReport.latitude.toFixed(6)}, {selectedReport.longitude.toFixed(6)}</span>
                </div>
                <div className="detail-row">
                  <span className="detail-row-label">Submitted</span>
                  <span>{new Date(selectedReport.created_at).toLocaleString('en-GB')}</span>
                </div>
                <div className="detail-row">
                  <span className="detail-row-label">Votes</span>
                  <span>👍 {selectedReport.upvotes} &nbsp; 👎 {selectedReport.downvotes}</span>
                </div>
                {selectedReport.description && (
                  <div style={{ borderTop: '1px solid var(--line)', paddingTop: 12, marginTop: 4 }}>
                    <p className="detail-row-label" style={{ marginBottom: 6 }}>Description</p>
                    <p style={{ margin: 0, lineHeight: 1.65, color: '#52617f' }}>{selectedReport.description}</p>
                  </div>
                )}
              </div>

              {isAdmin && (
                <div style={{ marginTop: 20 }}>
                  {getActionButtons(selectedReport)}
                </div>
              )}
            </div>
          ) : (
            <div className="empty-state">
              <strong>Select a report</strong>
              <p>Click any report card to inspect and moderate it here.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
