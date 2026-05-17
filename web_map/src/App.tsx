import { useEffect, useState } from 'react'
import 'maplibre-gl/dist/maplibre-gl.css'
import { MapView } from './components/MapView'
import type { DamageType, Report, ReportStats, ReportStatus, Severity } from './types'

const apiBaseUrl = (import.meta.env.VITE_API_BASE_URL as string | undefined)?.trim() || 'http://localhost:8000/api/v1'

const allDamageTypes: DamageType[] = ['Pothole', 'Crack', 'Broken Sign', 'Flooding', 'Debris', 'Other']
const allSeverityLevels: Severity[] = ['Low', 'Medium', 'High']
const allStatuses: ReportStatus[] = ['Verified', 'Rejected', 'Resolved']

type GeoJsonFeature = {
  geometry: { coordinates: [number, number] }
  properties: {
    id: string
    image_url: string
    damage_type: string
    severity: string
    status: string
    created_at: string
    description: string | null
    user_name: string
    user_points: number
  }
}

type ReportsStatsResponse = {
  total_reports: number
  verified_reports: number
  rejected_reports: number
  resolved_reports: number
  by_severity: Array<{ key: string; count: number }>
}

function titleizeEnum(value: string): string {
  return value
    .split('_')
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ') as DamageType | Severity | ReportStatus
}

function toDateFrom(range: 'all' | 'today' | 'week'): string | null {
  if (range === 'all') {
    return null
  }

  const now = new Date()
  const next = new Date(now)
  next.setHours(0, 0, 0, 0)

  if (range === 'week') {
    next.setDate(next.getDate() - 7)
  }

  return next.toISOString()
}

function buildQueryParams({
  damageTypes,
  severity,
  dateRange,
  status,
}: {
  damageTypes: DamageType[]
  severity: Severity[]
  dateRange: 'all' | 'today' | 'week'
  status: ReportStatus
}): URLSearchParams {
  const params = new URLSearchParams()
  params.set('limit', '200')

  if (damageTypes.length === 1) {
    params.set('damage_type', damageTypes[0].toLowerCase().replaceAll(' ', '_'))
  }
  if (severity.length === 1) {
    params.set('severity', severity[0].toLowerCase())
  }

  const dateFrom = toDateFrom(dateRange)
  if (dateFrom) {
    params.set('date_from', dateFrom)
  }

  params.set('status', status.toLowerCase())
  return params
}

function mapFeatureToReport(feature: GeoJsonFeature): Report {
  const [longitude, latitude] = feature.geometry.coordinates
  const damageType = titleizeEnum(feature.properties.damage_type) as DamageType
  const severity = titleizeEnum(feature.properties.severity) as Severity
  const status = titleizeEnum(feature.properties.status) as ReportStatus

  return {
    id: feature.properties.id,
    title: `${damageType} report`,
    damageType,
    severity,
    status,
    latitude,
    longitude,
    reportedAt: feature.properties.created_at,
    reporter: feature.properties.user_name || 'Anonymous',
    reporterPoints: feature.properties.user_points ?? 0,
    locationLabel: `${latitude.toFixed(5)}, ${longitude.toFixed(5)}`,
    description: feature.properties.description ?? 'No additional description was provided.',
    imageUrl: feature.properties.image_url,
  }
}

async function fetchStatusReports(
  status: ReportStatus,
  filters: {
    damageTypes: DamageType[]
    severity: Severity[]
    dateRange: 'all' | 'today' | 'week'
  },
): Promise<Report[]> {
  const params = buildQueryParams({ ...filters, status })
  const response = await fetch(`${apiBaseUrl}/reports/geojson?${params.toString()}`)
  if (!response.ok) {
    throw new Error(`Failed to load ${status.toLowerCase()} reports`)
  }

  const payload = (await response.json()) as { features?: GeoJsonFeature[] }
  return (payload.features ?? []).map(mapFeatureToReport)
}

async function fetchStatusStats(
  status: ReportStatus,
  filters: {
    damageTypes: DamageType[]
    severity: Severity[]
    dateRange: 'all' | 'today' | 'week'
  },
): Promise<ReportsStatsResponse> {
  const params = buildQueryParams({ ...filters, status })
  const response = await fetch(`${apiBaseUrl}/reports/stats?${params.toString()}`)
  if (!response.ok) {
    throw new Error(`Failed to load ${status.toLowerCase()} statistics`)
  }

  return (await response.json()) as ReportsStatsResponse
}

function App() {
  const [selectedDamageTypes, setSelectedDamageTypes] = useState<DamageType[]>(allDamageTypes)
  const [selectedSeverity, setSelectedSeverity] = useState<Severity[]>(allSeverityLevels)
  const [selectedStatuses, setSelectedStatuses] = useState<ReportStatus[]>(allStatuses)
  const [dateRange, setDateRange] = useState<'all' | 'today' | 'week'>('week')
  const [selectedReportId, setSelectedReportId] = useState('')
  const [reports, setReports] = useState<Report[]>([])
  const [stats, setStats] = useState<ReportStats>({
    totalReports: 0,
    highSeverityReports: 0,
    verifiedReports: 0,
    resolvedReports: 0,
    rejectedReports: 0,
  })
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false

    async function loadDashboard() {
      setIsLoading(true)
      setError(null)

      try {
        const activeStatuses = selectedStatuses.length > 0 ? selectedStatuses : allStatuses
        const filters = {
          damageTypes: selectedDamageTypes,
          severity: selectedSeverity,
          dateRange,
        }

        const [reportGroups, statsGroups] = await Promise.all([
          Promise.all(activeStatuses.map((status) => fetchStatusReports(status, filters))),
          Promise.all(activeStatuses.map((status) => fetchStatusStats(status, filters))),
        ])

        if (cancelled) {
          return
        }

        const nextReports = reportGroups.flat().sort((left, right) => {
          return new Date(right.reportedAt).getTime() - new Date(left.reportedAt).getTime()
        })

        const nextStats = statsGroups.reduce<ReportStats>(
          (accumulator, current) => {
            const highSeverityCount =
              current.by_severity.find((item) => item.key === 'high')?.count ?? 0

            return {
              totalReports: accumulator.totalReports + current.total_reports,
              highSeverityReports: accumulator.highSeverityReports + highSeverityCount,
              verifiedReports: accumulator.verifiedReports + current.verified_reports,
              resolvedReports: accumulator.resolvedReports + current.resolved_reports,
              rejectedReports: accumulator.rejectedReports + current.rejected_reports,
            }
          },
          {
            totalReports: 0,
            highSeverityReports: 0,
            verifiedReports: 0,
            resolvedReports: 0,
            rejectedReports: 0,
          },
        )

        setReports(nextReports)
        setStats(nextStats)
        setSelectedReportId((current) => {
          if (nextReports.some((report) => report.id === current)) {
            return current
          }
          return nextReports[0]?.id ?? ''
        })
      } catch (loadError) {
        if (!cancelled) {
          setError(loadError instanceof Error ? loadError.message : 'Failed to load the public dashboard.')
          setReports([])
          setStats({
            totalReports: 0,
            highSeverityReports: 0,
            verifiedReports: 0,
            resolvedReports: 0,
            rejectedReports: 0,
          })
          setSelectedReportId('')
        }
      } finally {
        if (!cancelled) {
          setIsLoading(false)
        }
      }
    }

    void loadDashboard()

    return () => {
      cancelled = true
    }
  }, [dateRange, selectedDamageTypes, selectedSeverity, selectedStatuses])

  const selectedReport = reports.find((report) => report.id === selectedReportId) ?? reports[0] ?? null

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
              <h1>Live road issue map</h1>
            </div>
            <button type="button" className="hero-notify">
              Live
            </button>
          </div>

          <p className="hero-description">
            Explore verified, rejected, and resolved citizen reports directly from the FastAPI and
            Supabase backend with live filters and map statistics.
          </p>

          <div className="hero-metrics">
            <div className="hero-score">
              <span className="hero-score-number">{stats.totalReports}</span>
              <div>
                <p className="metric-label">Visible reports</p>
                <strong>Live backend feed</strong>
              </div>
            </div>

            <div className="hero-progress-copy">
              <div className="hero-progress-head">
                <span>Current source</span>
                <strong>FastAPI + PostGIS</strong>
              </div>
              <div className="hero-progress">
                <div className="hero-progress-bar" />
              </div>
              <p>The web map is now consuming real report and statistics endpoints instead of mock data.</p>
            </div>
          </div>
        </div>

        <div className="cta-card">
          <div>
            <p className="eyebrow eyebrow-light">Public view</p>
            <h2>Explore active reports</h2>
            <p>
              Filter real reports by severity, type, lifecycle status, and recent activity across the
              city map.
            </p>
          </div>
          <div className="cta-icon">Live</div>
        </div>
      </section>

      <section className="stats-grid">
        <article className="stat-card">
          <span className="stat-icon">◎</span>
          <strong>{stats.totalReports}</strong>
          <span>Visible reports</span>
        </article>
        <article className="stat-card">
          <span className="stat-icon">▲</span>
          <strong>{stats.highSeverityReports}</strong>
          <span>High severity</span>
        </article>
        <article className="stat-card">
          <span className="stat-icon">✓</span>
          <strong>{stats.verifiedReports}</strong>
          <span>Verified</span>
        </article>
        <article className="stat-card">
          <span className="stat-icon">◌</span>
          <strong>{stats.resolvedReports + stats.rejectedReports}</strong>
          <span>Closed outcomes</span>
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
                <h3>{isLoading ? 'Loading issues...' : `${reports.length} visible issues`}</h3>
              </div>
            </div>

            {error ? (
              <div className="empty-state">
                <strong>Could not load the live dashboard.</strong>
                <p>{error}</p>
              </div>
            ) : isLoading ? (
              <div className="empty-state">
                <strong>Loading live reports.</strong>
                <p>Fetching reports and map statistics from the backend.</p>
              </div>
            ) : reports.length === 0 ? (
              <div className="empty-state">
                <strong>No reports match these filters.</strong>
                <p>Broaden the selected filters to repopulate the map and report feed.</p>
              </div>
            ) : (
              reports.map((report) => (
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
                    {report.locationLabel} • {new Date(report.reportedAt).toLocaleDateString('en-GB')}
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
              reports={reports}
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
                    <span>{selectedReport.locationLabel}</span>
                    <span>
                      {selectedReport.reporter} • {selectedReport.reporterPoints} XP
                    </span>
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
