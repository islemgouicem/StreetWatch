import { useEffect } from 'react';
import { useMap } from 'react-leaflet';

type MapControllerProps = {
  activeCenter: [number, number] | null;
};

export function MapController({ activeCenter }: MapControllerProps) {
  const map = useMap();

  useEffect(() => {
    if (activeCenter) {
      map.flyTo(activeCenter, 15, { animate: true, duration: 1.0 });
    }
  }, [activeCenter, map]);

  return null;
}
