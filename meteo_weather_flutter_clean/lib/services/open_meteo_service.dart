import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_models.dart';

class OpenMeteoService {
  static const String _forecastBaseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _airQualityBaseUrl = 'https://air-quality-api.open-meteo.com/v1/air-quality';
  static const String _geocodingBaseUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  final http.Client _client;

  OpenMeteoService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches weather forecast from Open-Meteo API
  Future<Map<String, dynamic>?> fetchForecast({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_forecastBaseUrl).replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,surface_pressure,wind_speed_10m,wind_direction_10m,uv_index',
      'hourly': 'temperature_2m,relative_humidity_2m,precipitation_probability,weather_code,wind_speed_10m,visibility',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max',
      'timezone': 'auto',
      'forecast_days': '7',
    });

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (e) {
      // In case of network timeout or offline
    }
    return null;
  }

  /// Fetches air quality from Open-Meteo API
  Future<Map<String, dynamic>?> fetchAirQuality({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_airQualityBaseUrl).replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current': 'european_aqi,us_aqi,pm10,pm2_5,dust,alder_pollen,birch_pollen,grass_pollen,ragweed_pollen',
      'timezone': 'auto',
    });

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (e) {
      // Network failure
    }
    return null;
  }

  /// Searches cities using Open-Meteo Geocoding
  Future<List<CityLocation>> searchCities(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(_geocodingBaseUrl).replace(queryParameters: {
      'name': query,
      'count': '10',
      'language': 'ar',
      'format': 'json',
    });

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>?;
        if (results != null) {
          return results.map((item) {
            return CityLocation(
              name: item['name'] as String? ?? query,
              country: item['country'] as String? ?? 'العالم',
              latitude: (item['latitude'] as num).toDouble(),
              longitude: (item['longitude'] as num).toDouble(),
              admin1: item['admin1'] as String?,
              countryCode: item['country_code'] as String?,
            );
          }).toList();
        }
      }
    } catch (_) {}
    return [];
  }
}
