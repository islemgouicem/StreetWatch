export type DamageType =
  | 'Pothole'
  | 'Crack'
  | 'Broken Sign'
  | 'Flooding'
  | 'Debris'
  | 'Other'

export type Severity = 'Low' | 'Medium' | 'High'

export type ReportStatus = 'Verified' | 'Rejected' | 'Resolved'

export type Report = {
  id: string
  title: string
  damageType: DamageType
  severity: Severity
  status: ReportStatus
  latitude: number
  longitude: number
  reportedAt: string
  reporter: string
  reporterPoints: number
  locationLabel: string
  description: string
  imageUrl: string
}

export type ReportStats = {
  totalReports: number
  highSeverityReports: number
  verifiedReports: number
  resolvedReports: number
  rejectedReports: number
}
