import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import type { Report, Severity } from '../types';
import { getDamageTypeLabel, severityLabel, statusLabel } from '../types';
import { MapController } from './MapController';

type MapViewProps = {
  reports: Report[];
  selectedReport: Report | null;
  onSelectReport: (report: Report) => void;
};

// Fix default Leaflet marker assets resolving in Vite
delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png',
  iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png',
  shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
});

const createSeverityIcon = (color: string) =>
  new L.Icon({
    iconUrl: `https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-${color}.png`,
    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png',
    iconSize: [25, 41],
    iconAnchor: [12, 41],
    popupAnchor: [1, -34],
    shadowSize: [41, 41],
  });

const severityIcons: Record<Severity, L.Icon> = {
  low: createSeverityIcon('green'),
  medium: createSeverityIcon('orange'),
  high: createSeverityIcon('red'),
};

export function MapView({ reports, selectedReport, onSelectReport }: MapViewProps) {
  const defaultCenter: [number, number] = [36.7538, 3.0588];

  // If there are reports, center on the first one; otherwise use Algiers
  const center: [number, number] =
    reports.length > 0 ? [reports[0].latitude, reports[0].longitude] : defaultCenter;

  const activeCenter: [number, number] | null = selectedReport
    ? [selectedReport.latitude, selectedReport.longitude]
    : null;

  return (
    <div className="map-canvas">
      <MapContainer
        center={center}
        zoom={13}
        style={{ height: '100%', width: '100%', borderRadius: '8px' }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        <MapController activeCenter={activeCenter} />

        {reports.map((report) => (
          <Marker
            key={report.id}
            position={[report.latitude, report.longitude]}
            icon={severityIcons[report.severity] ?? severityIcons.medium}
            eventHandlers={{ click: () => onSelectReport(report) }}
          >
            <Popup className="premium-popup">
              <div style={{ maxWidth: '210px', color: '#000' }}>
                {report.image_url && (
                  <img
                    src={report.image_url}
                    alt={getDamageTypeLabel(report.damage_type)}
                    style={{
                      width: '100%',
                      height: '100px',
                      objectFit: 'cover',
                      borderRadius: '6px',
                      marginBottom: '0.5rem',
                    }}
                  />
                )}
                <h4 style={{ margin: '0 0 0.2rem', fontSize: '0.9rem', fontWeight: 700 }}>
                  {getDamageTypeLabel(report.damage_type)}
                </h4>
                {report.description && (
                  <p style={{ margin: '0 0 0.4rem', fontSize: '0.75rem', color: '#4b5563' }}>
                    {report.description}
                  </p>
                )}
                <div
                  style={{
                    display: 'flex',
                    justifyContent: 'space-between',
                    fontSize: '0.72rem',
                    borderTop: '1px solid #e5e7eb',
                    paddingTop: '0.4rem',
                    fontWeight: 600,
                    gap: '8px',
                  }}
                >
                  <span style={{ color: '#2563eb' }}>👤 {report.user_name}</span>
                  <span
                    style={{
                      color:
                        report.status === 'resolved'
                          ? '#059669'
                          : report.status === 'verified'
                          ? '#2563eb'
                          : report.status === 'rejected'
                          ? '#dc2626'
                          : '#d97706',
                    }}
                  >
                    {statusLabel[report.status]}
                  </span>
                </div>
                <div
                  style={{
                    marginTop: '0.3rem',
                    fontSize: '0.7rem',
                    color: '#6b7280',
                  }}
                >
                  👍 {report.upvotes} · 👎 {report.downvotes} · {severityLabel[report.severity]} severity
                </div>
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>
    </div>
  );
}
