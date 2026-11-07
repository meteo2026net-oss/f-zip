import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_meteo_weather/models/weather_models.dart';
import 'package:flutter_meteo_weather/services/open_meteo_service.dart';
import 'package:flutter_meteo_weather/services/weather_repository.dart';

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

Map<String, dynamic> forecastFixture() {
  final times = List<String>.generate(
    24,
    (index) => "2026-01-01T${index.toString().padLeft(2, '0')}:00",
  );
  return {
    "current": {
      "time": "2026-01-01T12:00",
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
    },
    "daily": {
      "time": ["2026-01-01"],
      "weather_code": [3],
      "temperature_2m_max": [24.0],
      "temperature_2m_min": [15.0],
      "precipitation_probability_max": [10],
      "sunrise": ["2026-01-01T06:30"],
      "sunset": ["2026-01-01T17:00"],
      "uv_index_max": [4.0],
    },
  };
}

void main() {
  group('MCNC Weather data integrity', () {
    test('Maps WMO snow, freezing rain and unknown codes conservatively', () {
      expect(WeatherRepository.mapWeatherCode(85), WeatherConditionType.SNOW);
      expect(WeatherRepository.mapWeatherCode(66), WeatherConditionType.HEAVY_RAIN);
      expect(WeatherRepository.mapWeatherCode(999), WeatherConditionType.CLOUDY);
      expect(WeatherRepository.getWeatherConditionText(999, true), "ظاهرة جوية غير مصنفة");
    });

    test('Uses the current hour as the start of hourly forecast', () async {
      final repository = WeatherRepository(
        apiService: FakeOpenMeteoService(forecastFixture()),
      );
      final city = WeatherRepository.defaultSyrianCities.first;
      final weather = await repository.getFullWeather(city);

      expect(weather.hourlyList, isNotEmpty);
      expect(weather.hourlyList.first.time, "2026-01-01T12:00");
      expect(weather.hourlyList.any((hour) => hour.time == "2026-01-01T00:00"), isFalse);
      expect(weather.current.visibilityMeters, 10000.0);
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
      expect(weather.pollen.overallLevelAr, "لا تتوفر بيانات لقاح موثوقة");
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
}
