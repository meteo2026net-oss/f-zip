import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_meteo_weather/models/weather_models.dart';
import 'package:flutter_meteo_weather/services/open_meteo_service.dart';
import 'package:flutter_meteo_weather/services/weather_repository.dart';
import 'package:flutter_meteo_weather/widgets/interactive_weather_map.dart';

class FakeOpenMeteoService extends OpenMeteoService {
  FakeOpenMeteoService(this.forecast);

  final Map<String, dynamic>? forecast;

  @override
  Future<Map<String, dynamic>?> fetchForecast({
    required double latitude,
    required double longitude,
  }) async => forecast;

  @override
  Future<Map<String, dynamic>?> fetchAirQuality({
    required double latitude,
    required double longitude,
  }) async => null;
}

class ConcurrentOpenMeteoService extends OpenMeteoService {
  final forecastCompleter = Completer<Map<String, dynamic>?>();
  final airQualityCompleter = Completer<Map<String, dynamic>?>();
  bool forecastRequested = false;
  bool airQualityRequested = false;

  @override
  Future<Map<String, dynamic>?> fetchForecast({
    required double latitude,
    required double longitude,
  }) {
    forecastRequested = true;
    return forecastCompleter.future;
  }

  @override
  Future<Map<String, dynamic>?> fetchAirQuality({
    required double latitude,
    required double longitude,
  }) {
    airQualityRequested = true;
    return airQualityCompleter.future;
  }
}

Map<String, dynamic> forecastFixture() {
  final times = List<String>.generate(
    24,
    (index) => "2026-01-01T${index.toString().padLeft(2, '0')}:00",
  );
  final dailyDates = List<String>.generate(
    16,
    (index) => DateTime(2026, 1, 1).add(Duration(days: index)).toIso8601String().substring(0, 10),
  );
  return {
    "current": {
      "time": "2026-01-01T12:15",
      "temperature_2m": 22.0,
      "relative_humidity_2m": 48,
      "apparent_temperature": 21.0,
      "is_day": 1,
      "precipitation": 0.0,
      "weather_code": 3,
      "surface_pressure": 1012.0,
      "wind_speed_10m": 12.0,
      "wind_direction_10m": 270.0,
      "uv_index": 4.0,
    },
    "hourly": {
      "time": times,
      "temperature_2m": List<num>.generate(24, (i) => 20 + i / 10),
      "relative_humidity_2m": List<int>.filled(24, 48),
      "precipitation_probability": List<int>.filled(24, 10),
      "weather_code": List<int>.filled(24, 3),
      "wind_speed_10m": List<num>.filled(24, 12),
      "visibility": List<num>.filled(24, 10000),
      "is_day": List<int>.generate(24, (i) => i >= 6 && i < 18 ? 1 : 0),
    },
    "daily": {
      "time": dailyDates,
      "weather_code": List<int>.filled(16, 3),
      "temperature_2m_max": List<double>.filled(16, 24.0),
      "temperature_2m_min": List<double>.filled(16, 15.0),
      "precipitation_probability_max": List<int>.filled(16, 10),
      "sunrise": List<String>.generate(16, (i) => "${dailyDates[i]}T06:30"),
      "sunset": List<String>.generate(16, (i) => "${dailyDates[i]}T17:00"),
      "uv_index_max": List<double>.filled(16, 4.0),
    },
  };
}

void _ignoreStation(SyrianWeatherStation station) {}

void main() {
  group('Open-Meteo geocoding validation', () {
    test('skips malformed and out-of-range city coordinates', () async {
      late Uri requestedUri;
      final client = MockClient((request) async {
        requestedUri = request.url;
        return http.Response.bytes(
          utf8.encode(jsonEncode({
            'results': [
              {
                'name': 'دمشق',
              'country': 'سوريا',
              'latitude': 33.5138,
              'longitude': 36.2765,
              'admin1': 'محافظة دمشق',
              'country_code': 'SY',
            },
            {
              'name': 'Invalid latitude',
              'country': 'Test',
              'latitude': 95,
              'longitude': 10,
            },
            {
              'name': 'Invalid longitude',
              'country': 'Test',
              'latitude': 20,
              'longitude': -181,
            },
            {
              'name': 'String coordinate',
              'country': 'Test',
              'latitude': '30',
              'longitude': 30,
            },
              'not-a-city',
            ],
          })),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final service = OpenMeteoService(client: client);

      final cities = await service.searchCities('  دمشق  ');

      expect(requestedUri.queryParameters['name'], 'دمشق');
      expect(cities, hasLength(1));
      expect(cities.single.name, 'دمشق');
      expect(cities.single.latitude, 33.5138);
      expect(cities.single.longitude, 36.2765);
      client.close();
    });

    test('does not send a request for a blank city query', () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response('{}', 200);
      });
      final service = OpenMeteoService(client: client);

      expect(await service.searchCities('   '), isEmpty);
      expect(requestCount, 0);
      client.close();
    });
  });
  group('Open-Meteo service failure handling', () {
    test('returns unavailable forecast data for an HTTP error', () async {
      final client = MockClient((request) async => http.Response('service unavailable', 503));
      final service = OpenMeteoService(client: client);

      expect(
        await service.fetchForecast(latitude: 33.5138, longitude: 36.2765),
        isNull,
      );
      service.dispose();
    });

    test('returns unavailable air-quality data for malformed JSON', () async {
      final client = MockClient((request) async => http.Response('{invalid', 200));
      final service = OpenMeteoService(client: client);

      expect(
        await service.fetchAirQuality(latitude: 33.5138, longitude: 36.2765),
        isNull,
      );
      service.dispose();
    });
  });

  group('MCNC Weather data integrity', () {
    test('Maps WMO snow, freezing rain and unknown codes conservatively', () {
      expect(WeatherRepository.mapWeatherCode(85), WeatherConditionType.SNOW);
      expect(WeatherRepository.mapWeatherCode(66), WeatherConditionType.HEAVY_RAIN);
      expect(WeatherRepository.mapWeatherCode(999), WeatherConditionType.CLOUDY);
      expect(WeatherRepository.getWeatherConditionText(999, true), "ظاهرة جوية غير مصنفة");
    });

    test('Requests forecast and air quality concurrently', () async {
      final service = ConcurrentOpenMeteoService();
      final repository = WeatherRepository(apiService: service);

      final weatherFuture = repository.getFullWeather(
        WeatherRepository.defaultSyrianCities.first,
      );

      expect(service.forecastRequested, isTrue);
      expect(service.airQualityRequested, isTrue);

      service.forecastCompleter.complete(forecastFixture());
      service.airQualityCompleter.complete(null);
      final weather = await weatherFuture;

      expect(weather.current.temperatureCelsius, 22.0);
      repository.dispose();
    });

    test('Uses the current hour as the start of hourly forecast', () async {
      final repository = WeatherRepository(
        apiService: FakeOpenMeteoService(forecastFixture()),
      );
      final city = WeatherRepository.defaultSyrianCities.first;
      final weather = await repository.getFullWeather(city);

      expect(weather.hourlyList, isNotEmpty);
      expect(weather.hourlyList.first.time, "2026-01-01T13:00");
      expect(weather.hourlyList.any((hour) => hour.time == "2026-01-01T00:00"), isFalse);
      expect(weather.hourlyList.first.isDay, isTrue);
      expect(weather.hourlyList.last.isDay, isFalse);
      expect(weather.current.visibilityMeters, 10000.0);
      expect(weather.dailyList, hasLength(16));
      expect(weather.dailyList[2].dayLabel, contains("/"));
    });

    test('Marks visibility unavailable when the nearest hourly value is too old', () async {
      final fixture = forecastFixture();
      (fixture['current'] as Map<String, dynamic>)['time'] = "2026-01-02T02:00";
      final repository = WeatherRepository(
        apiService: FakeOpenMeteoService(fixture),
      );

      final weather = await repository.getFullWeather(
        WeatherRepository.defaultSyrianCities.first,
      );

      expect(weather.current.visibilityMeters, isNull);
    });

    test('Rejects impossible current humidity and day/night values', () async {
      final humidityFixture = forecastFixture();
      (humidityFixture['current'] as Map<String, dynamic>)['relative_humidity_2m'] = 140;
      final humidityRepository = WeatherRepository(
        apiService: FakeOpenMeteoService(humidityFixture),
      );
      expect(
        humidityRepository.getFullWeather(WeatherRepository.defaultSyrianCities.first),
        throwsA(isA<FormatException>()),
      );

      final dayFixture = forecastFixture();
      (dayFixture['current'] as Map<String, dynamic>)['is_day'] = 2;
      final dayRepository = WeatherRepository(
        apiService: FakeOpenMeteoService(dayFixture),
      );
      expect(
        dayRepository.getFullWeather(WeatherRepository.defaultSyrianCities.first),
        throwsA(isA<FormatException>()),
      );
    });

    test('Does not fabricate air quality when the service has no data', () async {
      final repository = WeatherRepository(
        apiService: FakeOpenMeteoService(forecastFixture()),
      );
      final weather = await repository.getFullWeather(
        WeatherRepository.defaultSyrianCities.first,
      );

      expect(weather.airQuality.aqi, -1);
      expect(weather.airQuality.statusAr, "بيانات جودة الهواء غير متاحة");
      expect(weather.pollen.overallLevelAr, "غير متاح");
    });

    test('Returns no official alert when no alert threshold is met', () async {
      final repository = WeatherRepository(
        apiService: FakeOpenMeteoService(forecastFixture()),
      );
      final weather = await repository.getFullWeather(
        WeatherRepository.defaultSyrianCities.first,
      );

      expect(weather.alerts, isEmpty);
    });

    test('Reports forecast unavailability instead of generating simulated readings', () async {
      final repository = WeatherRepository(apiService: FakeOpenMeteoService(null));
      expect(
        repository.getFullWeather(WeatherRepository.defaultSyrianCities.first),
        throwsA(isA<WeatherDataUnavailableException>()),
      );
    });
  });

  group('Historical monthly archive', () {
    test('requests the latest completed 30-day window and parses values', () async {
      late Uri requestedUri;
      final client = MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'daily': {
              'time': ['2026-11-02', '2026-11-03'],
              'temperature_2m_max': [25.5, 26.0],
              'temperature_2m_min': [14.0, 13.5],
              'precipitation_sum': [0.0, 2.4],
              'wind_speed_10m_max': [18.0, 22.0],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final service = OpenMeteoService(client: client);

      final rows = await service.fetchHistoricalMonth(
        latitude: 33.5138,
        longitude: 36.2765,
        referenceDate: DateTime(2026, 11, 8),
      );

      expect(requestedUri.host, 'archive-api.open-meteo.com');
      expect(requestedUri.queryParameters['start_date'], '2026-10-05');
      expect(requestedUri.queryParameters['end_date'], '2026-11-03');
      expect(requestedUri.queryParameters['daily'],
          contains('precipitation_sum'));
      expect(rows, hasLength(2));
      expect(rows.last['maxTemp'], 26.0);
      expect(rows.last['precipitation'], 2.4);
      service.dispose();
    });

    test('returns an empty list for an unavailable archive response', () async {
      final client = MockClient((request) async => http.Response('unavailable', 503));
      final service = OpenMeteoService(client: client);

      expect(
        await service.fetchHistoricalMonth(
          latitude: 33.5138,
          longitude: 36.2765,
          referenceDate: DateTime(2026, 11, 8),
        ),
        isEmpty,
      );
      service.dispose();
    });
  });

  group('Interactive weather map robustness', () {
    testWidgets('renders safely when the station list is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InteractiveWeatherMap(
              stations: [],
              onStationSelected: _ignoreStation,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text("مواقع توضيحية"), findsOneWidget);
    });

    testWidgets('renders only available pins for a partial station list', (tester) async {
      final station = SyrianWeatherStation(
        id: "st_damascus",
        nameAr: "محطة دمشق",
        governorate: "دمشق",
        latitude: 33.5138,
        longitude: 36.2765,
        temperatureCelsius: 20,
        humidity: 50,
        pressureHpa: 1013,
        windSpeedKmh: 10,
        conditionAr: "صافٍ",
        conditionType: WeatherConditionType.CLEAR,
      );

      SyrianWeatherStation? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveWeatherMap(
              stations: [station],
              onStationSelected: (value) => selected = value,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text("دمشق"), findsOneWidget);
      await tester.tap(find.text("دمشق"));
      expect(selected, same(station));
    });

    testWidgets('plots all registered illustrative locations from their coordinates', (tester) async {
      final stations = WeatherRepository().getSyrianWeatherStations();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InteractiveWeatherMap(
              stations: stations,
              onStationSelected: _ignoreStation,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(stations, hasLength(13));
      expect(find.text('القامشلي'), findsOneWidget);
      expect(find.text('تدمر'), findsOneWidget);
      expect(find.text('السويداء'), findsOneWidget);
    });
  });

}
