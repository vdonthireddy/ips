/**
 * Map component using Maplibre GL JS (vanilla, no react wrapper).
 * Displays pipeline routes, stations, valves, and devices.
 * Uses free OpenStreetMap tiles - no API token required.
 */
import React, { useEffect, useState, useRef } from 'react';
import maplibregl from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';

const MAPLIBRE_STYLE = {
  version: 8,
  sources: {
    osm: {
      type: 'raster',
      url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      tileSize: 256,
    },
  },
  layers: [
    {
      id: 'osm',
      type: 'raster',
      source: 'osm',
    },
  ],
};

function Map({
  selectedRoute,
  showStations,
  showValves,
  showDevices,
  routeData,
  stationsData,
  valvesData,
  devicesData,
  onMapClick,
  onFeatureClick,
}) {
  const mapContainer = useRef(null);
  const map = useRef(null);
  const [popupInfo, setPopupInfo] = useState(null);

  useEffect(() => {
    if (map.current) return;
    if (!mapContainer.current) return;

    map.current = new maplibregl.Map({
      container: mapContainer.current,
      style: MAPLIBRE_STYLE,
      center: [-98.5795, 31.5],
      zoom: 5,
    });

    map.current.on('click', (e) => {
      if (onMapClick) onMapClick(e.lngLat);
    });

    return () => {
      if (map.current) {
        map.current.remove();
        map.current = null;
      }
    };
  }, [onMapClick]);

  const getRouteColor = (product) => {
    const colors = {
      'Crude Oil': '#ff0000',
      'Natural Gas': '#0066ff',
      'Refined Products': '#ffaa00',
      default: '#666666',
    };
    return colors[product] || colors.default;
  };

  const handleLayerClick = (e) => {
    if (!e.features?.length) return;
    const feature = e.features[0];
    if (feature.geometry?.coordinates) setPopupInfo(feature);
    if (onFeatureClick) onFeatureClick(feature);
  };

  useEffect(() => {
    if (!map.current || !routeData?.geometry) return;

    const sourceId = 'route-source';
    const layerId = 'route-line';

    if (map.current.getSource(sourceId)) {
      map.current.getSource(sourceId).setData(routeData);
    } else {
      map.current.addSource(sourceId, {
        type: 'geojson',
        data: routeData,
      });
      map.current.addLayer({
        id: layerId,
        type: 'line',
        source: sourceId,
        paint: {
          'line-color': getRouteColor(routeData.properties?.product),
          'line-width': 3,
          'line-opacity': 0.8,
        },
      });
    }
  }, [routeData]);

  useEffect(() => {
    if (!map.current) return;

    const manageLayer = (sourceId, layerId, data, paint) => {
      if (!data?.features?.length) {
        if (map.current.getSource(sourceId)) {
          if (map.current.getLayer(layerId)) map.current.removeLayer(layerId);
          map.current.removeSource(sourceId);
        }
        return;
      }

      if (map.current.getSource(sourceId)) {
        map.current.getSource(sourceId).setData(data);
        return;
      }

      map.current.addSource(sourceId, { type: 'geojson', data });
      map.current.addLayer({
        id: layerId,
        type: 'circle',
        source: sourceId,
        paint,
      });
      map.current.on('click', layerId, handleLayerClick);
    };

    manageLayer('stations-source', 'stations-layer', stationsData, {
      'circle-radius': 8,
      'circle-color': [
        'match',
        ['get', 'station_type'],
        'compressor', '#ff0000',
        'pump', '#ff6600',
        'regulator', '#0099cc',
        'reception', '#00aa00',
        'delivery', '#00aa00',
        '#cccccc',
      ],
      'circle-opacity': 0.8,
      'circle-stroke-width': 2,
      'circle-stroke-color': '#ffffff',
    });

    manageLayer('valves-source', 'valves-layer', valvesData, {
      'circle-radius': 6,
      'circle-color': '#ff9900',
      'circle-opacity': 0.8,
      'circle-stroke-width': 1,
      'circle-stroke-color': '#ffffff',
    });

    manageLayer('devices-source', 'devices-layer', devicesData, {
      'circle-radius': 6,
      'circle-color': '#9966ff',
      'circle-opacity': 0.8,
      'circle-stroke-width': 1,
      'circle-stroke-color': '#ffffff',
    });
  }, [showStations, stationsData, showValves, valvesData, showDevices, devicesData]);

  useEffect(() => {
    if (!map.current || !selectedRoute || !routeData?.bbox) return;
    const { min_lon, max_lon, min_lat, max_lat } = routeData.bbox;
    map.current.fitBounds([[min_lon, min_lat], [max_lon, max_lat]], {
      padding: 50,
      duration: 1000,
    });
  }, [selectedRoute, routeData]);

  return (
    <div className="relative w-full h-full">
      <div ref={mapContainer} style={{ width: '100%', height: '100%' }} />

      {popupInfo?.geometry?.coordinates && (
        <div
          className="absolute bg-white p-4 rounded shadow-lg z-10 max-w-xs"
          style={{ left: '20px', top: '20px' }}
        >
          <button
            onClick={() => setPopupInfo(null)}
            className="absolute top-2 right-2 text-gray-500 hover:text-gray-700 bg-gray-100 rounded-full w-6 h-6 flex items-center justify-center"
          >
            ✕
          </button>

          <h3 className="font-bold text-sm mb-2">
            {popupInfo.properties?.name || popupInfo.properties?.id || 'Feature'}
          </h3>

          <div className="text-xs text-gray-700 space-y-1">
            {popupInfo.properties?.station_type && (
              <div>
                <span className="font-semibold">Type:</span>{' '}
                {popupInfo.properties.station_type}
              </div>
            )}
            {popupInfo.properties?.valve_type && (
              <div>
                <span className="font-semibold">Type:</span>{' '}
                {popupInfo.properties.valve_type}
              </div>
            )}
            {popupInfo.properties?.device_type && (
              <div>
                <span className="font-semibold">Type:</span>{' '}
                {popupInfo.properties.device_type}
              </div>
            )}
            {popupInfo.properties?.diameter_inches && (
              <div>
                <span className="font-semibold">Diameter:</span>{' '}
                {popupInfo.properties.diameter_inches}"
              </div>
            )}
            {popupInfo.properties?.material && (
              <div>
                <span className="font-semibold">Material:</span>{' '}
                {popupInfo.properties.material}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

export default Map;
