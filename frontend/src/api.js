/**
 * API client for communicating with FastAPI backend.
 * Provides functions for fetching pipeline data.
 */
import axios from 'axios';

// Configure API base URL
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

const apiClient = axios.create({
  baseURL: `${API_BASE_URL}/api`,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add error interceptor for consistent error handling
apiClient.interceptors.response.use(
  response => response,
  error => {
    console.error('API Error:', error.response?.data || error.message);
    return Promise.reject(error);
  }
);

/**
 * Fetch all pipeline systems WITH nested routes.
 * @param {Object} params - Query parameters
 * @param {string} params.operator - Optional operator filter
 * @returns {Promise<Array>} List of pipeline systems with routes
 */
export async function getPipelineSystemsWithRoutes(params = {}) {
  try {
    const response = await apiClient.get('/systems-with-routes', { params });
    return response.data;
  } catch (error) {
    console.error('Failed to fetch pipeline systems with routes:', error);
    throw error;
  }
}

/**
 * Fetch all pipeline systems.
 * @param {Object} params - Query parameters
 * @param {string} params.operator - Optional operator filter
 * @returns {Promise<Array>} List of pipeline systems
 */
export async function getPipelineSystems(params = {}) {
  try {
    const response = await apiClient.get('/pipelines', { params });
    return response.data;
  } catch (error) {
    console.error('Failed to fetch pipeline systems:', error);
    throw error;
  }
}

/**
 * Fetch a single route with GeoJSON geometry.
 * @param {number} routeId - Route ID
 * @returns {Promise<Object>} GeoJSON Feature with route data
 */
export async function getRoute(routeId) {
  try {
    const response = await apiClient.get(`/pipelines/${routeId}`);
    return response.data;
  } catch (error) {
    console.error(`Failed to fetch route ${routeId}:`, error);
    throw error;
  }
}

/**
 * Fetch pipe segments for a route.
 * @param {number} routeId - Route ID
 * @returns {Promise<Object>} GeoJSON FeatureCollection of segments
 */
export async function getRouteSegments(routeId) {
  try {
    const response = await apiClient.get(`/pipelines/${routeId}/segments`);
    return response.data;
  } catch (error) {
    console.error(`Failed to fetch segments for route ${routeId}:`, error);
    throw error;
  }
}

/**
 * Fetch stations for a route.
 * @param {number} routeId - Route ID
 * @returns {Promise<Object>} GeoJSON FeatureCollection of stations
 */
export async function getRouteStations(routeId) {
  try {
    const response = await apiClient.get(`/pipelines/${routeId}/stations`);
    return response.data;
  } catch (error) {
    console.error(`Failed to fetch stations for route ${routeId}:`, error);
    throw error;
  }
}

/**
 * Fetch valves for a route.
 * @param {number} routeId - Route ID
 * @param {Object} params - Query parameters
 * @param {string} params.valve_type - Optional valve type filter
 * @returns {Promise<Object>} GeoJSON FeatureCollection of valves
 */
export async function getRouteValves(routeId, params = {}) {
  try {
    const response = await apiClient.get(`/pipelines/${routeId}/valves`, { params });
    return response.data;
  } catch (error) {
    console.error(`Failed to fetch valves for route ${routeId}:`, error);
    throw error;
  }
}

/**
 * Fetch inline devices for a route.
 * @param {number} routeId - Route ID
 * @param {Object} params - Query parameters
 * @param {string} params.device_type - Optional device type filter
 * @returns {Promise<Object>} GeoJSON FeatureCollection of devices
 */
export async function getRouteDevices(routeId, params = {}) {
  try {
    const response = await apiClient.get(`/pipelines/${routeId}/devices`, { params });
    return response.data;
  } catch (error) {
    console.error(`Failed to fetch devices for route ${routeId}:`, error);
    throw error;
  }
}

/**
 * Find routes near a point.
 * @param {number} longitude - Point longitude
 * @param {number} latitude - Point latitude
 * @param {number} distanceMiles - Search radius in miles
 * @returns {Promise<Object>} GeoJSON FeatureCollection of nearby routes
 */
export async function getRoutesNearPoint(longitude, latitude, distanceMiles = 10) {
  try {
    const response = await apiClient.get('/routes-near-point', {
      params: {
        longitude,
        latitude,
        distance_miles: distanceMiles,
      },
    });
    return response.data;
  } catch (error) {
    console.error('Failed to fetch routes near point:', error);
    throw error;
  }
}

/**
 * Find routes within a bounding box.
 * @param {number} minLon - Minimum longitude
 * @param {number} minLat - Minimum latitude
 * @param {number} maxLon - Maximum longitude
 * @param {number} maxLat - Maximum latitude
 * @returns {Promise<Object>} GeoJSON FeatureCollection of routes in bounds
 */
export async function getRoutesInBounds(minLon, minLat, maxLon, maxLat) {
  try {
    const response = await apiClient.get('/routes-in-bounds', {
      params: {
        min_lon: minLon,
        min_lat: minLat,
        max_lon: maxLon,
        max_lat: maxLat,
      },
    });
    return response.data;
  } catch (error) {
    console.error('Failed to fetch routes in bounds:', error);
    throw error;
  }
}

export default apiClient;
