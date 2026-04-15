export type DamageType = 'Pothole' | 'Crack' | 'Broken Sign' | 'Faded Marking'

export type Severity = 'Low' | 'Medium' | 'High'

export type ReportStatus = 'Pending' | 'Verified' | 'Resolved'

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
  district: string
  description: string
  imageUrl: string
}
