import { useEffect, useRef } from 'react'
import maplibregl, { type Map as MapLibreMap, Marker } from 'maplibre-gl'
import type { Report, Severity } from '../types'

type MapViewProps = {
  reports: Report[]
  selectedReport: Report | null
  onSelectReport: (report: Report) => void
}

const severityColors: Record<Severity, string> = {
  Low: '#7ed36f',
  Medium: '#f2a34f',
  High: '#f26b4c',
}

export function MapView({ reports, selectedReport, onSelectReport }: MapViewProps) {
  const containerRef = useRef<HTMLDivElement | null>(null)
  const mapRef = useRef<MapLibreMap | null>(null)
  const markersRef = useRef<Marker[]>([])

  useEffect(() => {
    if (!containerRef.current || mapRef.current) {
      return
    }

    const map = new maplibregl.Map({
      container: containerRef.current,
      style: 'https://demotiles.maplibre.org/style.json',
      center: [3.0588, 36.7538],
      zoom: 12.2,
      attributionControl: false,
    })

    map.addControl(new maplibregl.NavigationControl({ visualizePitch: true }), 'top-right')
    mapRef.current = map

    return () => {
      markersRef.current.forEach((marker) => marker.remove())
      markersRef.current = []
      map.remove()
      mapRef.current = null
    }
  }, [])

  useEffect(() => {
    const map = mapRef.current
    if (!map) {
      return
    }

    markersRef.current.forEach((marker) => marker.remove())
    markersRef.current = []

    reports.forEach((report) => {
      const element = document.createElement('button')
      element.type = 'button'
      element.className = `map-marker${selectedReport?.id === report.id ? ' is-selected' : ''}`
      element.style.setProperty('--marker-color', severityColors[report.severity])
      element.setAttribute('aria-label', `${report.damageType} at ${report.locationLabel}`)
      element.addEventListener('click', () => onSelectReport(report))

      const marker = new maplibregl.Marker({ element, anchor: 'bottom' })
        .setLngLat([report.longitude, report.latitude])
        .addTo(map)

      markersRef.current.push(marker)
    })

    if (reports.length === 0) {
      return
    }

    const bounds = reports.reduce(
      (accumulator, report) =>
        accumulator.extend([report.longitude, report.latitude] as [number, number]),
      new maplibregl.LngLatBounds(
        [reports[0].longitude, reports[0].latitude],
        [reports[0].longitude, reports[0].latitude],
      ),
    )
    map.fitBounds(bounds, {
      padding: 60,
      maxZoom: 14,
      duration: 800,
    })
  }, [reports, selectedReport, onSelectReport])

  useEffect(() => {
    const map = mapRef.current
    if (!map || !selectedReport) {
      return
    }

    map.flyTo({
      center: [selectedReport.longitude, selectedReport.latitude],
      zoom: 14.5,
      duration: 1000,
      essential: true,
    })
  }, [selectedReport])

  return <div ref={containerRef} className="map-canvas" />
}
