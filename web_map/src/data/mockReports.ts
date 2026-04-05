import type { Report } from '../types'

export const mockReports: Report[] = [
  {
    id: 'rep-001',
    title: 'Deep pothole near tram crossing',
    damageType: 'Pothole',
    severity: 'High',
    status: 'Verified',
    latitude: 36.7538,
    longitude: 3.0588,
    reportedAt: '2026-04-05T08:15:00Z',
    reporter: 'Alex Rivera',
    district: 'Didouche Mourad',
    description:
      'Large pothole affecting the right lane. Drivers are swerving into the next lane to avoid it.',
    imageUrl:
      'https://images.unsplash.com/photo-1517022812141-23620dba5c23?auto=format&fit=crop&w=900&q=80',
  },
  {
    id: 'rep-002',
    title: 'Surface cracking on uphill road',
    damageType: 'Crack',
    severity: 'Medium',
    status: 'Pending',
    latitude: 36.7611,
    longitude: 3.0402,
    reportedAt: '2026-04-04T16:45:00Z',
    reporter: 'Nina Patel',
    district: 'El Biar',
    description:
      'Longitudinal cracks visible across the shoulder and part of the driving lane.',
    imageUrl:
      'https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=900&q=80',
  },
  {
    id: 'rep-003',
    title: 'Bent warning sign after collision',
    damageType: 'Broken Sign',
    severity: 'Medium',
    status: 'Verified',
    latitude: 36.7427,
    longitude: 3.0865,
    reportedAt: '2026-04-03T11:30:00Z',
    reporter: 'Lina Chen',
    district: 'Belouizdad',
    description:
      'Road warning sign is bent and partially unreadable for incoming traffic.',
    imageUrl:
      'https://images.unsplash.com/photo-1482192596544-9eb780fc7f66?auto=format&fit=crop&w=900&q=80',
  },
  {
    id: 'rep-004',
    title: 'Faded pedestrian crossing paint',
    damageType: 'Faded Marking',
    severity: 'Low',
    status: 'Resolved',
    latitude: 36.7685,
    longitude: 3.0193,
    reportedAt: '2026-04-02T09:05:00Z',
    reporter: 'Karim Haddad',
    district: 'Ben Aknoun',
    description:
      'Crosswalk paint is barely visible, especially early in the morning.',
    imageUrl:
      'https://images.unsplash.com/photo-1482192505345-5655af888cc4?auto=format&fit=crop&w=900&q=80',
  },
  {
    id: 'rep-005',
    title: 'Cluster of potholes near bus stop',
    damageType: 'Pothole',
    severity: 'High',
    status: 'Pending',
    latitude: 36.7372,
    longitude: 3.0674,
    reportedAt: '2026-04-05T06:50:00Z',
    reporter: 'Omar Salem',
    district: 'Hamma',
    description:
      'Multiple potholes have formed close together near the bus stop shelter.',
    imageUrl:
      'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=900&q=80',
  },
  {
    id: 'rep-006',
    title: 'Shoulder cracking along curve',
    damageType: 'Crack',
    severity: 'Low',
    status: 'Verified',
    latitude: 36.7754,
    longitude: 3.0542,
    reportedAt: '2026-04-01T14:20:00Z',
    reporter: 'Sara Benali',
    district: 'Hydra',
    description:
      'Minor cracking along the shoulder; currently not blocking traffic but getting wider.',
    imageUrl:
      'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?auto=format&fit=crop&w=900&q=80',
  },
]
