import { useEffect, useState, useCallback } from 'react';
import { MapView } from '../components/MapView';
import type { DamageType, Report, ReportStatus, Severity } from '../types';
import { damageTypeLabel, getDamageTypeLabel, normalizeDamageType, severityLabel, statusLabel } from '../types';

const BACKEND_URL = 'http://localhost:8000/api/v1';

const allDamageTypes: DamageType[] = ['pothole', 'longitudinal_crack', 'transverse_crack', 'alligator_crack', 'other'];
const allSeverityLevels: Severity[] = ['low', 'medium', 'high'];
const allStatuses: ReportStatus[] = ['pending', 'verified', 'rejected', 'resolved'];

export default function MapPage() {
  const [allReports, setAllReports] = useState<Report[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedReportId, setSelectedReportId] = useState<string | null>(null);

  // Filters
  const [selectedDamageTypes, setSelectedDamageTypes] = useState<DamageType[]>(allDamageTypes);
  const [selectedSeverity, setSelectedSeverity] = useState<Severity[]>(allSeverityLevels);
  const [selectedStatuses, setSelectedStatuses] = useState<ReportStatus[]>(allStatuses);
  const [dateRange, setDateRange] = useState<'all' | 'today' | 'week'>('all');
  const [searchQuery, setSearchQuery] = useState('');

  const loadReports = useCallback(async () => {
    try {
      setIsLoading(true);
      setError(null);
      const res = await fetch(`${BACKEND_URL}/reports`);
      if (!res.ok) throw new Error(`Server error: ${res.status}`);
      const data: Report[] = await res.json();
      setAllReports(data);
      if (data.length > 0) setSelectedReportId(data[0].id);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to connect to backend.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    loadReports();
    // Poll every 30 seconds for new reports
    const interval = setInterval(loadReports, 30000);
    return () => clearInterval(interval);
  }, [loadReports]);

  const toggleFilter = <T extends string>(
    current: T[],
    value: T,
    setState: (next: T[]) => void,
    fullList: T[],
  ) => {
    const exists = current.includes(value);
    const next = exists ? current.filter((item) => item !== value) : [...current, value];
    setState(next.length > 0 ? next : fullList);
  };

  const filteredReports = allReports.filter((r) => {
    const damageType = normalizeDamageType(r.damage_type);
    if (!selectedDamageTypes.includes(damageType)) return false;
    if (!selectedSeverity.includes(r.severity)) return false;
    if (!selectedStatuses.includes(r.status)) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      const matches =
        r.user_name.toLowerCase().includes(q) ||
        (r.description ?? '').toLowerCase().includes(q) ||
        getDamageTypeLabel(r.damage_type).toLowerCase().includes(q);
      if (!matches) return false;
    }
    if (dateRange !== 'all') {
      const created = new Date(r.created_at);
      const cutoff = new Date();
      if (dateRange === 'today') cutoff.setHours(0, 0, 0, 0);
      else if (dateRange === 'week') cutoff.setDate(cutoff.getDate() - 7);
      if (created < cutoff) return false;
    }
    return true;
  });

  const stats = {
    total: allReports.length,
    high: allReports.filter((r) => r.severity === 'high').length,
    pending: allReports.filter((r) => r.status === 'pending').length,
    verified: allReports.filter((r) => r.status === 'verified').length,
    resolved: allReports.filter((r) => r.status === 'resolved').length,
    rejected: allReports.filter((r) => r.status === 'rejected').length,
  };

  const selectedReport =
    filteredReports.find((r) => r.id === selectedReportId) ?? filteredReports[0] ?? null;

  return (
    <main className="app-shell">
      {/* ── HEADER ── */}
      <section className="top-grid">
        <div className="hero-card">
          <div className="hero-topline">
            <div>
              <p className="eyebrow">StreetWatch Public Dashboard</p>
              <h1>Live road issue map</h1>
            </div>
            <span className="hero-notify">Live</span>
          </div>
          <p className="hero-description">
            Real-time road damage reports submitted by citizens via the StreetWatch mobile app —
            displayed with exact GPS coordinates on an interactive map.
          </p>
          <div className="hero-metrics">
            <div className="hero-score">
              <span className="hero-score-number">{stats.total}</span>
              <div>
                <p className="metric-label">Total Reports</p>
                <strong>From mobile app</strong>
              </div>
            </div>
            <div className="hero-progress-copy">
              <div className="hero-progress-head">
                <span>Resolution rate</span>
                <strong>
                  {stats.total > 0 ? Math.round((stats.resolved / stats.total) * 100) : 0}%
                </strong>
              </div>
              <div className="hero-progress">
                <div
                  className="hero-progress-bar"
                  style={{ width: stats.total > 0 ? `${(stats.resolved / stats.total) * 100}%` : '0%' }}
                />
              </div>
              <p>{stats.resolved} of {stats.total} reports resolved by city crews.</p>
            </div>
          </div>
        </div>

        <div className="cta-card">
          <div>
            <p className="eyebrow eyebrow-light">Auto-refresh every 30s</p>
            <h2>Citizen reports</h2>
            <p>
              Reports flow directly from the StreetWatch mobile app. Each pin shows
              the exact location captured by the reporter's GPS.
            </p>
          </div>
          <button
            type="button"
            className="cta-icon"
            onClick={() => loadReports()}
            title="Refresh reports now"
          >
            ↺
          </button>
        </div>
      </section>

      {/* ── STATS ── */}
      <section className="stats-grid">
        <article className="stat-card">
          <span className="stat-icon">◎</span>
          <strong>{stats.total}</strong>
          <span>Total Reports</span>
        </article>
        <article className="stat-card">
          <span className="stat-icon">▲</span>
          <strong>{stats.high}</strong>
          <span>High Severity</span>
        </article>
        <article className="stat-card">
          <span className="stat-icon">⏳</span>
          <strong>{stats.pending}</strong>
          <span>Pending</span>
        </article>
        <article className="stat-card">
          <span className="stat-icon">✓</span>
          <strong>{stats.verified + stats.resolved}</strong>
          <span>Verified / Resolved</span>
        </article>
      </section>

      {/* ── MAIN GRID ── */}
      <section className="main-grid">
        {/* LEFT COLUMN — Filters + Feed */}
        <aside className="left-column">
          {/* Search */}
          <section className="panel">
            <div className="panel-heading">
              <div>
                <p className="section-label">Search</p>
                <h3>Find reports</h3>
              </div>
              <button
                type="button"
                className="ghost-button"
                onClick={() => {
                  setSelectedDamageTypes(allDamageTypes);
                  setSelectedSeverity(allSeverityLevels);
                  setSelectedStatuses(allStatuses);
                  setDateRange('all');
                  setSearchQuery('');
                }}
              >
                Reset
              </button>
            </div>
            <input
              type="text"
              className="sim-input"
              placeholder="Search by user, type, description…"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              style={{ marginBottom: 0 }}
            />
          </section>

          {/* Filters */}
          <section className="panel filters-panel">
            <div className="panel-heading">
              <div>
                <p className="section-label">Dashboard filters</p>
                <h3>Refine the map</h3>
              </div>
            </div>

            <div className="filter-group">
              <span className="filter-label">Damage type</span>
              <div className="chip-grid">
                {allDamageTypes.map((type) => (
                  <button
                    key={type}
                    type="button"
                    className={`filter-chip${selectedDamageTypes.includes(type) ? ' active' : ''}`}
                    onClick={() => toggleFilter(selectedDamageTypes, type, setSelectedDamageTypes, allDamageTypes)}
                  >
                    {damageTypeLabel[type]}
                  </button>
                ))}
              </div>
            </div>

            <div className="filter-group">
              <span className="filter-label">Severity</span>
              <div className="chip-grid">
                {allSeverityLevels.map((level) => (
                  <button
                    key={level}
                    type="button"
                    className={`filter-chip${selectedSeverity.includes(level) ? ' active' : ''}`}
                    onClick={() => toggleFilter(selectedSeverity, level, setSelectedSeverity, allSeverityLevels)}
                  >
                    {severityLabel[level]}
                  </button>
                ))}
              </div>
            </div>

            <div className="filter-group">
              <span className="filter-label">Status</span>
              <div className="chip-grid">
                {allStatuses.map((status) => (
                  <button
                    key={status}
                    type="button"
                    className={`filter-chip${selectedStatuses.includes(status) ? ' active' : ''}`}
                    onClick={() => toggleFilter(selectedStatuses, status, setSelectedStatuses, allStatuses)}
                  >
                    {statusLabel[status]}
                  </button>
                ))}
              </div>
            </div>

            <div className="filter-group">
              <span className="filter-label">Date range</span>
              <div className="chip-grid">
                {[
                  { label: 'Today', value: 'today' },
                  { label: 'This Week', value: 'week' },
                  { label: 'All Time', value: 'all' },
                ].map((opt) => (
                  <button
                    key={opt.value}
                    type="button"
                    className={`filter-chip${dateRange === opt.value ? ' active' : ''}`}
                    onClick={() => setDateRange(opt.value as 'today' | 'week' | 'all')}
                  >
                    {opt.label}
                  </button>
                ))}
              </div>
            </div>
          </section>

          {/* Report Feed */}
          <section className="panel reports-panel">
            <div className="panel-heading compact">
              <div>
                <p className="section-label">Report feed</p>
                <h3>
                  {isLoading
                    ? 'Loading…'
                    : `${filteredReports.length} visible report${filteredReports.length !== 1 ? 's' : ''}`}
                </h3>
              </div>
            </div>

            {error ? (
              <div className="empty-state">
                <strong>Could not load reports.</strong>
                <p>{error}</p>
                <button type="button" className="ghost-button" style={{ marginTop: 12 }} onClick={loadReports}>
                  Retry
                </button>
              </div>
            ) : isLoading ? (
              <div className="empty-state">
                <strong>Fetching live reports…</strong>
                <p>Connecting to the StreetWatch backend.</p>
              </div>
            ) : filteredReports.length === 0 ? (
              <div className="empty-state">
                <strong>No reports match these filters.</strong>
                <p>Try broadening your filter selection.</p>
              </div>
            ) : (
              filteredReports.map((report) => (
                <button
                  key={report.id}
                  type="button"
                  className={`report-row${selectedReport?.id === report.id ? ' active' : ''}`}
                  onClick={() => setSelectedReportId(report.id)}
                >
                  <div className="report-row-head">
                    <strong>{getDamageTypeLabel(report.damage_type)}</strong>
                    <span className={`severity-pill severity-${report.severity}`}>
                      {severityLabel[report.severity]}
                    </span>
                  </div>
                  <span style={{ fontWeight: 600, color: 'var(--text)', fontSize: '0.82rem' }}>
                    👤 {report.user_name}
                    {report.user_points != null ? ` · ${report.user_points} XP` : ''}
                  </span>
                  <span>
                    {report.latitude.toFixed(5)}, {report.longitude.toFixed(5)}
                    {' · '}
                    {new Date(report.created_at).toLocaleDateString('en-GB')}
                  </span>
                </button>
              ))
            )}
          </section>
        </aside>

        {/* RIGHT COLUMN — Map + Detail */}
        <section className="right-column">
          <section className="panel map-panel">
            <div className="panel-heading">
              <div>
                <p className="section-label">Live GPS Map</p>
                <h3>Road damage overview</h3>
              </div>
              <div className="legend">
                <span><i className="legend-dot low" /> Low</span>
                <span><i className="legend-dot medium" /> Medium</span>
                <span><i className="legend-dot high" /> High</span>
              </div>
            </div>
            <MapView
              reports={filteredReports}
              selectedReport={selectedReport}
              onSelectReport={(report: Report) => setSelectedReportId(report.id)}
            />
          </section>

          {/* Detail Panel */}
          <section className="panel detail-panel">
            {selectedReport ? (
              <>
                {selectedReport.image_url && (
                  <div className="detail-image-wrap">
                    <img
                      src={selectedReport.image_url}
                      alt={getDamageTypeLabel(selectedReport.damage_type)}
                      className="detail-image"
                    />
                    <span className={`severity-pill floating severity-${selectedReport.severity}`}>
                      {severityLabel[selectedReport.severity]}
                    </span>
                  </div>
                )}

                <div className="detail-content">
                  <div className="detail-head">
                    <div>
                      <p className="section-label">Selected report</p>
                      <h3>{getDamageTypeLabel(selectedReport.damage_type)}</h3>
                    </div>
                    <span className={`status-badge status-${selectedReport.status}`}>
                      {statusLabel[selectedReport.status]}
                    </span>
                  </div>

                  {selectedReport.description && (
                    <p className="detail-description">{selectedReport.description}</p>
                  )}

                  <div className="detail-meta">
                    <span>📍 {selectedReport.latitude.toFixed(6)}, {selectedReport.longitude.toFixed(6)}</span>
                    <span>👤 {selectedReport.user_name}</span>
                    {selectedReport.user_points != null && (
                      <span>⭐ {selectedReport.user_points} XP</span>
                    )}
                    <span>🗓 {new Date(selectedReport.created_at).toLocaleString('en-GB')}</span>
                    <span>👍 {selectedReport.upvotes} · 👎 {selectedReport.downvotes}</span>
                    {selectedReport.distance_meters != null && (
                      <span>📏 {(selectedReport.distance_meters / 1000).toFixed(2)} km away</span>
                    )}
                  </div>
                </div>
              </>
            ) : (
              <div className="empty-state" style={{ gridColumn: '1 / -1' }}>
                <strong>Select a report.</strong>
                <p>Click any map marker or report card to see its full details here.</p>
              </div>
            )}
          </section>
        </section>
      </section>
    </main>
  )
}
