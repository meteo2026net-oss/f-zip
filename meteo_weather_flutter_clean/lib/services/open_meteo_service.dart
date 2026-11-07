import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_models.dart';

class OpenMeteoService {
  static const String _forecastBaseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _airQualityBaseUrl = 'https://air-quality-api.open-meteo.com/v1/air-quality';
  static const String _geocodingBaseUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  final http.Client _client;

  OpenMeteoService({http.Client? client}) : _client = client ?? http.Client();

  void dispose() => _client.close();

  /// Fetches weather forecast from Open-Meteo API
  Future<Map<String, dynamic>?> fetchForecast({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_forecastBaseUrl).replace(queryParameters: {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,surface_pressure,wind_speed_10m,wind_direction_10m,uv_index',
      'hourly': 'temperature_2m,relative_humidity_2m,precipitation_probability,weather_code,wind_speed_10m,visibility,is_day',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max',
      'timezone': 'auto',
      'forecast_days': '16',
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

  /// Fetches the latest 30 complete days from Open-Meteo's historical archive.
  /// These are reanalysis estimates, not direct observations from a local station.
  Future<List<Map<String, dynamic>>> fetchHistoricalMonth({
    required double latitude,
    required double longitude,
    DateTime? referenceDate,
  }) async {
    final end = (referenceDate ?? DateTime.now()).subtract(const Duration(days: 5));
    final start = end.subtract(const Duration(days: 29));
    String dateParam(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse('https://archive-api.open-meteo.com/v1/archive').replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'start_date': dateParam(start),
        'end_date': dateParam(end),
        'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum,wind_speed_10m_max',
        'timezone': 'auto',
      },
    );

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return [];
      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) return [];
      final daily = decoded['daily'];
      if (daily is! Map) return [];
      final dates = daily['time'];
      final maxTemps = daily['temperature_2m_max'];
      final minTemps = daily['temperature_2m_min'];
      final precipitation = daily['precipitation_sum'];
      final wind = daily['wind_speed_10m_max'];
      if (dates is! List || maxTemps is! List || minTemps is! List ||
          precipitation is! List || wind is! List) return [];

      final length = [dates.length, maxTemps.length, minTemps.length,
        precipitation.length, wind.length].reduce((a, b) => a < b ? a : b);
      final rows = <Map<String, dynamic>>[];
      for (var i = 0; i < length; i++) {
        if (dates[i] is! String) continue;
        rows.add({
          'date': dates[i],
          'maxTemp': (maxTemps[i] as num?)?.toDouble(),
          'minTemp': (minTemps[i] as num?)?.toDouble(),
          'precipitation': (precipitation[i] as num?)?.toDouble(),
          'maxWind': (wind[i] as num?)?.toDouble(),
        });
      }
      return rows;
    } catch (_) {
      return [];
    }
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

    final normalizedQuery = query.trim();
    final uri = Uri.parse(_geocodingBaseUrl).replace(queryParameters: {
      'name': normalizedQuery,
      'count': '10',
      'language': 'ar',
      'format': 'json',
    });

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return [];

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) return [];
      final results = decoded['results'];
      if (results is! List) return [];

      final cities = <CityLocation>[];
      for (final item in results) {
        if (item is! Map) continue;
        final latitude = item['latitude'];
        final longitude = item['longitude'];
        if (latitude is! num ||
            longitude is! num ||
            !latitude.isFinite ||
            !longitude.isFinite ||
            latitude < -90 ||
            latitude > 90 ||
            longitude < -180 ||
            longitude > 180) {
          continue;
        }

        final name = item['name'];
        final country = item['country'];
        final admin1 = item['admin1'];
        final countryCode = item['country_code'];
        cities.add(CityLocation(
          name: name is String && name.trim().isNotEmpty
              ? name
              : normalizedQuery,
          country: country is String && country.trim().isNotEmpty
              ? country
              : 'العالم',
          latitude: latitude.toDouble(),
          longitude: longitude.toDouble(),
          admin1: admin1 is String ? admin1 : null,
          countryCode: countryCode is String ? countryCode : null,
        ));
      }
      return cities;
    } catch (_) {
      return [];
    }
  }
}
