/**
 * Main React application component.
 * Integrates map, pipeline list, and controls.
 */
import React, { useEffect, useState } from 'react';
import Map from './Map';
import PipelineList from './PipelineList';
import {
  getRoute,
  getRouteSegments,
  getRouteStations,
  getRouteValves,
  getRouteDevices,
} from './api';

function App() {
  const [selectedRoute, setSelectedRoute] = useState(null);
  const [routeData, setRouteData] = useState(null);
  const [stationsData, setStationsData] = useState(null);
  const [valvesData, setValvesData] = useState(null);
  const [devicesData, setDevicesData] = useState(null);
  const [segmentsData, setSegmentsData] = useState(null);

  const [showSegments, setShowSegments] = useState(true);
  const [showStations, setShowStations] = useState(true);
  const [showValves, setShowValves] = useState(true);
  const [showDevices, setShowDevices] = useState(true);

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);
  const [selectedFeature, setSelectedFeature] = useState(null);

  // Fetch all data when route is selected
  useEffect(() => {
    if (!selectedRoute) {
      setRouteData(null);
      setStationsData(null);
      setValvesData(null);
      setDevicesData(null);
      return;
    }

    fetchRouteData(selectedRoute.id);
  }, [selectedRoute]);

  // Fetch route geometry
  const fetchRouteData = async (routeId) => {
    setIsLoading(true);
    setError(null);

    try {
      const route = await getRoute(routeId);
      setRouteData(route);

      // Fetch stations, valves, devices, and segments
      const [stations, valves, devices, segments] = await Promise.all([
        getRouteStations(routeId),
        getRouteValves(routeId),
        getRouteDevices(routeId),
        getRouteSegments(routeId),
      ]);

      setStationsData(stations);
      setValvesData(valves);
      setDevicesData(devices);
      setSegmentsData(segments);
    } catch (err) {
      setError(`Failed to load route data: ${err.message}`);
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  };

  // Fetch segments when toggle is enabled
  useEffect(() => {
    if (showSegments && selectedRoute && !segmentsData) {
      fetchSegments(selectedRoute.id);
    }
  }, [showSegments, selectedRoute]);

  const fetchSegments = async (routeId) => {
    try {
      const segments = await getRouteSegments(routeId);
      setSegmentsData(segments);
    } catch (err) {
      console.error('Failed to load segments:', err);
    }
  };

  const handleRouteSelect = (route) => {
    setSelectedRoute({
      id: route.id,
      name: route.name,
      properties: route,
    });
  };

  const handleFeatureClick = (feature) => {
    setSelectedFeature(feature);
  };

  return (
    <div className="flex h-screen bg-gray-100 font-sans">
      {/* Sidebar with pipeline list */}
      <div className="w-80 bg-white shadow-lg flex flex-col">
        <PipelineList
          selectedRoute={selectedRoute}
          onRouteSelect={handleRouteSelect}
          onOperatorFilter={() => {}}
          loading={isLoading}
          error={error}
        />
      </div>

      {/* Main content area */}
      <div className="flex-1 flex flex-col">
        {/* Control Panel */}
        <div className="bg-white shadow px-6 py-4 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <div>
              {selectedRoute ? (
                <div>
                  <h1 className="text-2xl font-bold text-gray-800">
                    {selectedRoute.name}
                  </h1>
                  <p className="text-sm text-gray-600 mt-1">
                    Route ID: {selectedRoute.id}
                  </p>
                </div>
              ) : (
                <h1 className="text-2xl font-bold text-gray-500">
                  Select a pipeline route to begin
                </h1>
              )}
            </div>

            {/* Feature Details Panel */}
            {selectedFeature && (
              <div className="ml-6 px-4 py-2 bg-blue-50 border border-blue-200 rounded-lg">
                <h3 className="text-sm font-semibold text-blue-900">
                  {selectedFeature.properties?.name || 'Feature Details'}
                </h3>
                <p className="text-xs text-blue-700 mt-1">
                  {selectedFeature.properties?.station_type ||
                    selectedFeature.properties?.valve_type ||
                    selectedFeature.properties?.device_type ||
                    'Feature'}
                </p>
              </div>
            )}
          </div>

          {/* Layer Toggle Buttons */}
          {selectedRoute && (
            <div className="mt-4 flex flex-wrap gap-3">
              <button
                onClick={() => setShowSegments(!showSegments)}
                className={`px-4 py-2 rounded text-sm font-medium transition-colors ${
                  showSegments
                    ? 'bg-blue-500 text-white'
                    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                }`}
              >
                {showSegments ? '✓' : '○'} Segments
              </button>

              <button
                onClick={() => setShowStations(!showStations)}
                className={`px-4 py-2 rounded text-sm font-medium transition-colors ${
                  showStations
                    ? 'bg-green-500 text-white'
                    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                }`}
              >
                {showStations ? '✓' : '○'} Stations ({stationsData?.features?.length || 0})
              </button>

              <button
                onClick={() => setShowValves(!showValves)}
                className={`px-4 py-2 rounded text-sm font-medium transition-colors ${
                  showValves
                    ? 'bg-orange-500 text-white'
                    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                }`}
              >
                {showValves ? '✓' : '○'} Valves ({valvesData?.features?.length || 0})
              </button>

              <button
                onClick={() => setShowDevices(!showDevices)}
                className={`px-4 py-2 rounded text-sm font-medium transition-colors ${
                  showDevices
                    ? 'bg-purple-500 text-white'
                    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                }`}
              >
                {showDevices ? '✓' : '○'} Devices ({devicesData?.features?.length || 0})
              </button>
            </div>
          )}

          {/* Error message */}
          {error && (
            <div className="mt-3 p-3 bg-red-50 border border-red-200 rounded text-sm text-red-700">
              {error}
            </div>
          )}

          {/* Loading indicator */}
          {isLoading && (
            <div className="mt-3 flex items-center gap-2 text-sm text-gray-600">
              <div className="inline-block animate-spin rounded-full h-4 w-4 border-b-2 border-blue-500"></div>
              Loading route data...
            </div>
          )}
        </div>

        {/* Map area */}
        <div className="flex-1 relative">
          <Map
            selectedRoute={selectedRoute}
            showSegments={showSegments}
            showStations={showStations}
            showValves={showValves}
            showDevices={showDevices}
            routeData={routeData}
            segmentsData={segmentsData}
            stationsData={stationsData}
            valvesData={valvesData}
            devicesData={devicesData}
            onFeatureClick={handleFeatureClick}
          />
        </div>
      </div>
    </div>
  );
}

export default App;
