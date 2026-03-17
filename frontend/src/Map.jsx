/**
 * Map component using Maplibre GL JS (vanilla, no react wrapper).
 * Displays pipeline routes, stations, valves, and devices.
 * Uses free OpenStreetMap tiles - no API token required.
 */
import React, { useEffect, useState, useRef } from 'react';
import maplibregl from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';

// Use local static MapLibre tiles (hosted in Docker)
const MAPLIBRE_STYLE = 'http://localhost:8080/style.json';

function Map({
  selectedRoute,
  showSegments,
  showStations,
  showValves,
  showDevices,
  routeData,
  segmentsData,
  stationsData,
  valvesData,
  devicesData,
  onMapClick,
  onFeatureClick,
}) {
  const mapContainer = useRef(null);
  const map = useRef(null);
  const [popupInfo, setPopupInfo] = useState(null);
  const [hoverInfo, setHoverInfo] = useState(null);

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

    // Add mouse move listener for hover effects
    map.current.on('mousemove', 'segments-layer', (e) => {
      if (e.features.length > 0) {
        const feature = e.features[0];
        setHoverInfo({
          properties: feature.properties,
          x: e.point.x,
          y: e.point.y
        });
        map.current.getCanvas().style.cursor = 'pointer';
      }
    });

    map.current.on('mouseleave', 'segments-layer', () => {
      setHoverInfo(null);
      map.current.getCanvas().style.cursor = '';
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
          'line-opacity': showSegments ? 0.2 : 0.8, // Dim main route if segments shown
        },
      });
    }
  }, [routeData, showSegments]);

  useEffect(() => {
    if (!map.current) return;

    const manageLayer = (sourceId, layerId, data, type, paint, isVisible) => {
      const hasSource = map.current.getSource(sourceId);
      const hasLayer = map.current.getLayer(layerId);

      if (!isVisible || !data?.features?.length) {
        if (hasLayer) map.current.removeLayer(layerId);
        if (hasSource) map.current.removeSource(sourceId);
        return;
      }

      if (hasSource) {
        map.current.getSource(sourceId).setData(data);
        if (!hasLayer) {
          map.current.addLayer({ id: layerId, type, source: sourceId, paint });
        }
      } else {
        map.current.addSource(sourceId, { type: 'geojson', data });
        map.current.addLayer({ id: layerId, type, source: sourceId, paint });
        map.current.on('click', layerId, handleLayerClick);
      }
    };

    // Define hover listeners for segments
    let hoveredId = null;
    const onSegmentMouseMove = (e) => {
      if (e.features.length > 0) {
        if (hoveredId !== null) {
          map.current.setFeatureState(
            { source: 'segments-source', id: hoveredId },
            { hover: false }
          );
        }
        hoveredId = e.features[0].id;
        map.current.setFeatureState(
          { source: 'segments-source', id: hoveredId },
          { hover: true }
        );
      }
    };

    const onSegmentMouseLeave = () => {
      if (hoveredId !== null) {
        map.current.setFeatureState(
          { source: 'segments-source', id: hoveredId },
          { hover: false }
        );
      }
      hoveredId = null;
    };

    // Render Segments
    manageLayer('segments-source', 'segments-layer', segmentsData, 'line', {
      'line-color': [
        'case',
        ['boolean', ['feature-state', 'hover'], false],
        '#ffff00', // Yellow on hover
        ['==', ['%', ['to-number', ['get', 'id']], 2], 0],
        '#333333', // Dark black (off-black)
        '#666666'  // Light black (gray)
      ],
      'line-width': [
        'case',
        ['boolean', ['feature-state', 'hover'], false],
        8,
        5
      ],
      'line-opacity': 1.0,
    }, showSegments);

    // Add hover highlighting logic
    if (map.current && showSegments && segmentsData?.features?.length) {
      map.current.on('mousemove', 'segments-layer', onSegmentMouseMove);
      map.current.on('mouseleave', 'segments-layer', onSegmentMouseLeave);
    }

    manageLayer('stations-source', 'stations-layer', stationsData, 'circle', {
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
    }, showStations);

    manageLayer('valves-source', 'valves-layer', valvesData, 'circle', {
      'circle-radius': 6,
      'circle-color': '#ff9900',
      'circle-opacity': 0.8,
      'circle-stroke-width': 1,
      'circle-stroke-color': '#ffffff',
    }, showValves);

    manageLayer('devices-source', 'devices-layer', devicesData, 'circle', {
      'circle-radius': 6,
      'circle-color': '#9966ff',
      'circle-opacity': 0.8,
      'circle-stroke-width': 1,
      'circle-stroke-color': '#ffffff',
    }, showDevices);

    // Return cleanup for this effect's listeners
    return () => {
      if (map.current && map.current.getLayer('segments-layer')) {
        map.current.off('mousemove', 'segments-layer', onSegmentMouseMove);
        map.current.off('mouseleave', 'segments-layer', onSegmentMouseLeave);
      }
    };
  }, [showSegments, segmentsData, showStations, stationsData, showValves, valvesData, showDevices, devicesData]);

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
      <div ref={mapContainer} className="w-full h-full" />

      {/* Hover Tooltip for Segments */}
      {hoverInfo && (
        <div
          className="absolute pointer-events-none bg-black bg-opacity-80 text-white p-2 rounded text-xs z-20 shadow-xl"
          style={{ left: hoverInfo.x + 15, top: hoverInfo.y - 15 }}
        >
          <div className="font-bold border-b border-gray-600 mb-1 pb-1">
            Pipe Segment #{hoverInfo.properties.id}
          </div>
          <div><span className="text-gray-400">Length:</span> {hoverInfo.properties.length} miles</div>
          <div><span className="text-gray-400">Range:</span> {hoverInfo.properties.from_measure} - {hoverInfo.properties.to_measure}</div>
          <div><span className="text-gray-400">Specs:</span> {hoverInfo.properties.diameter_inches}" {hoverInfo.properties.material} {hoverInfo.properties.grade}</div>
        </div>
      )}

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
