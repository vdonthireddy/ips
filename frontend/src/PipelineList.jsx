/**
 * Pipeline list sidebar component.
 * Displays list of pipeline systems and routes for selection.
 */
import React, { useEffect, useState } from 'react';
import { getPipelineSystemsWithRoutes } from './api';

function PipelineList({
  selectedRoute,
  onRouteSelect,
  onOperatorFilter,
  loading,
  error,
}) {
  const [systems, setSystems] = useState([]);
  const [expandedSystem, setExpandedSystem] = useState(null);
  const [filterOperator, setFilterOperator] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [listError, setListError] = useState(null);

  // Fetch pipeline systems on mount and when filter changes
  useEffect(() => {
    fetchSystems();
  }, [filterOperator]);

  const fetchSystems = async () => {
    if (!filterOperator && systems.length > 0) {
      return; // Don't refetch if no filter and already have data
    }

    setIsLoading(true);
    setListError(null);

    try {
      const params = filterOperator ? { operator: filterOperator } : {};
      const data = await getPipelineSystemsWithRoutes(params);
      setSystems(data || []);
    } catch (err) {
      setListError('Failed to load pipeline systems');
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSystemClick = (systemId) => {
    setExpandedSystem(expandedSystem === systemId ? null : systemId);
  };

  const handleRouteSelect = (route) => {
    onRouteSelect(route);
  };

  const handleFilterChange = (e) => {
    const value = e.target.value;
    setFilterOperator(value);
    onOperatorFilter(value);
  };

  return (
    <div className="flex flex-col h-full bg-white shadow-lg overflow-hidden">
      {/* Header */}
      <div className="px-4 py-4 border-b border-gray-200 flex-shrink-0">
        <h2 className="text-lg font-bold text-gray-800">Pipeline Systems</h2>
        <p className="text-sm text-gray-500 mt-1">Select a route to view details</p>
      </div>

      {/* Filter */}
      <div className="px-4 py-3 border-b border-gray-200 flex-shrink-0">
        <input
          type="text"
          placeholder="Filter by operator..."
          value={filterOperator}
          onChange={handleFilterChange}
          className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:border-blue-500 text-sm"
        />
      </div>

      {/* Error message */}
      {listError && (
        <div className="px-4 py-3 bg-red-50 border-b border-red-200 text-sm text-red-700">
          {listError}
        </div>
      )}

      {/* Loading state */}
      {isLoading && (
        <div className="px-4 py-8 text-center text-gray-500 flex-1">
          <div className="inline-block animate-spin rounded-full h-6 w-6 border-b-2 border-blue-500"></div>
          <p className="mt-2 text-sm">Loading pipeline systems...</p>
        </div>
      )}

      {/* Systems list */}
      <div className="flex-1 overflow-y-auto">
        {!isLoading && systems.length === 0 && (
          <div className="px-4 py-8 text-center text-gray-500 text-sm">
            No pipeline systems found
          </div>
        )}

        {systems.map((system) => (
          <div key={system.id} className="border-b border-gray-100">
            {/* System header (clickable to expand) */}
            <button
              onClick={() => handleSystemClick(system.id)}
              className="w-full px-4 py-3 text-left hover:bg-gray-50 transition-colors flex items-between justify-between"
            >
              <div className="flex-1">
                <h3 className="font-semibold text-sm text-gray-800">
                  {system.name}
                </h3>
                <p className="text-xs text-gray-600 mt-1">
                  Operator: {system.operator_name}
                </p>
                <p className="text-xs text-gray-500 mt-1">
                  {system.product}
                  {system.region && ` • ${system.region}`}
                </p>
                <p className="text-xs text-gray-500 mt-1">
                  {system.route_count} route{system.route_count !== 1 ? 's' : ''}
                </p>
              </div>
              <div className="text-gray-400 ml-2">
                {expandedSystem === system.id ? '▼' : '▶'}
              </div>
            </button>

            {/* Routes list (visible when expanded) */}
            {expandedSystem === system.id && (
              <div className="bg-gray-50 border-t border-gray-100">
                <div className="px-4 py-2 text-xs font-semibold text-gray-700 uppercase tracking-wide bg-gray-100">
                  Routes
                </div>
                
                {system.routes && system.routes.length > 0 ? (
                  system.routes.map((route) => (
                    <button
                      key={route.id}
                      onClick={() => handleRouteSelect(route)}
                      className={`w-full px-6 py-2 text-left text-sm transition-colors border-l-4 ${
                        selectedRoute?.id === route.id
                          ? 'bg-blue-50 border-blue-500 text-blue-900'
                          : 'hover:bg-gray-100 border-transparent text-gray-700'
                      }`}
                    >
                      <div className="flex items-center gap-2">
                        <div
                          className="w-2 h-2 rounded-full"
                          style={{
                            backgroundColor:
                              route.product === 'Crude Oil'
                                ? '#ff0000'
                                : route.product === 'Natural Gas'
                                ? '#0066ff'
                                : '#ffaa00',
                          }}
                        ></div>
                        <span className="font-medium">{route.name}</span>
                      </div>
                      {route.length_miles && (
                        <div className="text-xs text-gray-500 mt-1 ml-4">
                          {Math.round(route.length_miles)} miles
                        </div>
                      )}
                    </button>
                  ))
                ) : (
                  <div className="px-6 py-3 text-xs text-gray-500">
                    No routes available
                  </div>
                )}
              </div>
            )}
          </div>
        ))}
      </div>

      {/* Footer info */}
      <div className="px-4 py-3 bg-gray-50 border-t border-gray-200 text-xs text-gray-600 flex-shrink-0">
        <p>Total systems: {systems.length}</p>
      </div>
    </div>
  );
}

export default PipelineList;
