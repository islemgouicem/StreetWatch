export type DamageType = 'pothole' | 'longitudinal_crack' | 'transverse_crack' | 'alligator_crack' | 'other'

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

export const damageTypeLabel: Record<DamageType, string> = {
  pothole: 'Pothole',
  longitudinal_crack: 'Longitudinal Crack',
  transverse_crack: 'Transverse Crack',
  alligator_crack: 'Alligator Crack',
  other: 'Other Damage',
}

export function normalizeDamageType(value: string | null | undefined): DamageType {
  const normalized = (value ?? '').trim().toLowerCase().replace(/[-\s]+/g, '_')

  switch (normalized) {
    case 'pothole':
    case 'longitudinal_crack':
    case 'transverse_crack':
    case 'alligator_crack':
      return normalized
    case 'other':
    case 'other_damage':
    case 'other_damages':
    default:
      return 'other'
  }
}

export function getDamageTypeLabel(value: string | null | undefined): string {
  return damageTypeLabel[normalizeDamageType(value)]
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
