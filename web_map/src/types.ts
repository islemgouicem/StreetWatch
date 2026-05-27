// Matches the Python backend + Flutter model schema exactly
export type DamageType = 'pothole' | 'crack' | 'flooding' | 'debris' | 'other'

export type Severity = 'low' | 'medium' | 'high'

export type ReportStatus = 'pending' | 'verified' | 'rejected' | 'resolved'

export type Report = {
  id: string
  user_id: string
  image_url: string | null
  damage_type: DamageType
  severity: Severity
  description: string | null
  latitude: number
  longitude: number
  status: ReportStatus
  upvotes: number
  downvotes: number
  created_at: string
  updated_at: string | null
  user_name: string
  user_points: number | null
  distance_meters: number | null
}

// Convenience display labels
export const damageTypeLabel: Record<DamageType, string> = {
  pothole: 'Pothole',
  crack: 'Crack',
  flooding: 'Flooding',
  debris: 'Debris',
  other: 'Other',
}

export const severityLabel: Record<Severity, string> = {
  low: 'Low',
  medium: 'Medium',
  high: 'High',
}

export const statusLabel: Record<ReportStatus, string> = {
  pending: 'Pending',
  verified: 'Verified',
  rejected: 'Rejected',
  resolved: 'Resolved',
}
