import { useState } from 'react'
import 'maplibre-gl/dist/maplibre-gl.css'
import { MapView } from './components/MapView'
import { mockReports } from './data/mockReports'
import type { DamageType, Report, ReportStatus, Severity } from './types'

const allDamageTypes: DamageType[] = ['Pothole', 'Crack', 'Broken Sign', 'Faded Marking']
const allSeverityLevels: Severity[] = ['Low', 'Medium', 'High']
const allStatuses: ReportStatus[] = ['Pending', 'Verified', 'Resolved']

function App() {
  const [selectedDamageTypes, setSelectedDamageTypes] = useState<DamageType[]>(allDamageTypes)
  const [selectedSeverity, setSelectedSeverity] = useState<Severity[]>(allSeverityLevels)
  const [selectedStatuses, setSelectedStatuses] = useState<ReportStatus[]>(allStatuses)
  const [dateRange, setDateRange] = useState<'all' | 'today' | 'week'>('week')
  const [selectedReportId, setSelectedReportId] = useState<string>(mockReports[0]?.id ?? '')

  const filteredReports = mockReports.filter((report) => {
    if (!selectedDamageTypes.includes(report.damageType)) {
      return false
    }

    if (!selectedSeverity.includes(report.severity)) {
      return false
    }

    if (!selectedStatuses.includes(report.status)) {
      return false
    }

    if (dateRange === 'all') {
      return true
    }

    const reportTime = new Date(report.reportedAt).getTime()
    const now = new Date('2026-04-05T12:00:00Z').getTime()
    const oneDay = 24 * 60 * 60 * 1000
    const rangeLimit = dateRange === 'today' ? oneDay : 7 * oneDay

    return now - reportTime <= rangeLimit
  })

  const selectedReport =
    filteredReports.find((report) => report.id === selectedReportId) ?? filteredReports[0] ?? null

  const totalReports = filteredReports.length
  const highSeverityReports = filteredReports.filter((report) => report.severity === 'High').length
  const verifiedReports = filteredReports.filter((report) => report.status === 'Verified').length
  const districtsCovered = new Set(filteredReports.map((report) => report.district)).size

  function toggleFilter<T extends string>(
    current: T[],
    value: T,
    setState: (next: T[]) => void,
    fullList: T[],
  ) {
    const exists = current.includes(value)
    const next = exists ? current.filter((item) => item !== value) : [...current, value]
    setState(next.length > 0 ? next : fullList)
  }

  return (
    <main className="app-shell">
      <section className="top-grid">
        <div className="hero-card">
          <div className="hero-topline">
            <div>
              <p className="eyebrow">StreetWatch Public Dashboard</p>
              <h1>Public road issue map</h1>
            </div>
            <button type="button" className="hero-notify">
              3
            </button>
          </div>

          <p className="hero-description">
            Track potholes, cracks, broken signs, and faded markings through a cleaner public map
            interface built with dummy data and structured for backend integration next.
          </p>

          <div className="hero-metrics">
            <div className="hero-score">
              <span className="hero-score-number">12</span>
              <div>
                <p className="metric-label">Current phase</p>
                <strong>Web Map MVP</strong>
              </div>
            </div>

            <div className="hero-progress-copy">
              <div className="hero-progress-head">
                <span>Delivery progress</span>
                <strong>#3 Public Map</strong>
              </div>
              <div className="hero-progress">
                <div className="hero-progress-bar" />
              </div>
              <p>Map rendering, filters, statistics, and dummy data structure are in place.</p>
            </div>
          </div>
        </div>

        <div className="cta-card">
          <div>
            <p className="eyebrow eyebrow-light">Public view</p>
            <h2>Explore active reports</h2>
            <p>
              Filter issues by severity, type, verification status, and date without relying on a
              backend yet.
            </p>
          </div>
          <div className="cta-icon">Map</div>
        </div>
      </section>

      <section className="stats-grid">
        <article className="stat-card">
          <span className="stat-icon">◎</span>
          <strong>{totalReports}</strong>
          <span>Visible reports</span>
        </article>
        <article className="stat-card">
          <span className="stat-icon">▲</span>
          <strong>{highSeverityReports}</strong>
          <span>High severity</span>
        </article>
        <article className="stat-card">
          <span className="stat-icon">✓</span>
          <strong>{verifiedReports}</strong>
          <span>Verified</span>
        </article>
        <article className="stat-card">
          <span className="stat-icon">◌</span>
          <strong>{districtsCovered}</strong>
          <span>Districts covered</span>
        </article>
      </section>

      <section className="main-grid">
        <aside className="left-column">
          <section className="panel filters-panel">
            <div className="panel-heading">
              <div>
                <p className="section-label">Dashboard filters</p>
                <h3>Refine the map</h3>
              </div>
              <button
                type="button"
                className="ghost-button"
                onClick={() => {
                  setSelectedDamageTypes(allDamageTypes)
                  setSelectedSeverity(allSeverityLevels)
                  setSelectedStatuses(allStatuses)
                  setDateRange('week')
                }}
              >
                Reset
              </button>
            </div>

            <div className="filter-group">
              <span className="filter-label">Damage type</span>
              <div className="chip-grid">
                {allDamageTypes.map((type) => (
                  <button
                    key={type}
                    type="button"
                    className={`filter-chip${selectedDamageTypes.includes(type) ? ' active' : ''}`}
                    onClick={() =>
                      toggleFilter(selectedDamageTypes, type, setSelectedDamageTypes, allDamageTypes)
                    }
                  >
                    {type}
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
                    onClick={() =>
                      toggleFilter(selectedSeverity, level, setSelectedSeverity, allSeverityLevels)
                    }
                  >
                    {level}
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
                    onClick={() =>
                      toggleFilter(selectedStatuses, status, setSelectedStatuses, allStatuses)
                    }
                  >
                    {status}
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
                  { label: 'All', value: 'all' },
                ].map((option) => (
                  <button
                    key={option.value}
                    type="button"
                    className={`filter-chip${dateRange === option.value ? ' active' : ''}`}
                    onClick={() => setDateRange(option.value as 'today' | 'week' | 'all')}
                  >
                    {option.label}
                  </button>
                ))}
              </div>
            </div>
          </section>

          <section className="panel reports-panel">
            <div className="panel-heading compact">
              <div>
                <p className="section-label">Report feed</p>
                <h3>{filteredReports.length} visible issues</h3>
              </div>
            </div>

            {filteredReports.length === 0 ? (
              <div className="empty-state">
                <strong>No reports match these filters.</strong>
                <p>Broaden the selected filters to repopulate the map and report feed.</p>
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
                    <strong>{report.title}</strong>
                    <span className={`severity-pill severity-${report.severity.toLowerCase()}`}>
                      {report.severity}
                    </span>
                  </div>
                  <span>{report.damageType}</span>
                  <span>
                    {report.district} • {new Date(report.reportedAt).toLocaleDateString('en-GB')}
                  </span>
                </button>
              ))
            )}
          </section>
        </aside>

        <section className="right-column">
          <section className="panel map-panel">
            <div className="panel-heading">
              <div>
                <p className="section-label">Public map view</p>
                <h3>Road damage overview</h3>
              </div>
              <div className="legend">
                <span>
                  <i className="legend-dot low" /> Low
                </span>
                <span>
                  <i className="legend-dot medium" /> Medium
                </span>
                <span>
                  <i className="legend-dot high" /> High
                </span>
              </div>
            </div>
            <MapView
              reports={filteredReports}
              selectedReport={selectedReport}
              onSelectReport={(report: Report) => setSelectedReportId(report.id)}
            />
          </section>

          <section className="panel detail-panel">
            {selectedReport ? (
              <>
                <div className="detail-image-wrap">
                  <img src={selectedReport.imageUrl} alt={selectedReport.title} className="detail-image" />
                  <span className={`severity-pill floating severity-${selectedReport.severity.toLowerCase()}`}>
                    {selectedReport.severity}
                  </span>
                </div>

                <div className="detail-content">
                  <div className="detail-head">
                    <div>
                      <p className="section-label">Selected report</p>
                      <h3>{selectedReport.title}</h3>
                    </div>
                    <span className="status-badge">{selectedReport.status}</span>
                  </div>

                  <p className="detail-description">{selectedReport.description}</p>

                  <div className="detail-meta">
                    <span>{selectedReport.damageType}</span>
                    <span>{selectedReport.district}</span>
                    <span>{selectedReport.reporter}</span>
                    <span>{new Date(selectedReport.reportedAt).toLocaleString('en-GB')}</span>
                  </div>
                </div>
              </>
            ) : (
              <div className="empty-state">
                <strong>Select a visible report.</strong>
                <p>Click any marker or report card to inspect its details here.</p>
              </div>
            )}
          </section>
        </section>
      </section>
    </main>
  )
}

export default App
