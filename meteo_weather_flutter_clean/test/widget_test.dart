import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_meteo_weather/models/weather_models.dart';
import 'package:flutter_meteo_weather/services/weather_repository.dart';
import 'package:flutter_meteo_weather/services/gemini_assistant_service.dart';

void main() {
  group('MCNC Weather Repository Tests', () {
    final repository = WeatherRepository();

    test('Loads 13 official Syrian weather stations', () {
      final stations = repository.getSyrianWeatherStations();
      expect(stations.length, equals(13));
      expect(stations.any((s) => s.id == "st_damascus"), isTrue);
      expect(stations.any((s) => s.id == "st_aleppo"), isTrue);
      expect(stations.any((s) => s.id == "st_latakia"), isTrue);
      expect(stations.any((s) => s.id == "st_palmyra"), isTrue);
    });

    test('Loads default Syrian governorates and cities', () {
      expect(WeatherRepository.defaultSyrianCities.length, greaterThanOrEqualTo(10));
      expect(WeatherRepository.defaultSyrianCities.first.name, equals("دمشق"));
    });

    test('Retrieves official audio bulletin', () {
      final bulletin = repository.getAudioBulletin();
      expect(bulletin.title.contains("النشرة الجوية"), isTrue);
      expect(bulletin.announcerName.contains("MCNC"), isTrue);
    });

    test('Generates severe alerts correctly', () async {
      final damascus = WeatherRepository.defaultSyrianCities.first;
      final fullWeather = await repository.getFullWeather(damascus);
      expect(fullWeather.alerts.isNotEmpty, isTrue);
      expect(fullWeather.hourlyList.length, equals(24));
      expect(fullWeather.dailyList.length, equals(7));
    });

    test('Gemini weather assistant generates clothing and travel advice', () async {
      final damascus = WeatherRepository.defaultSyrianCities.first;
      final fullWeather = await repository.getFullWeather(damascus);

      final replyClothing = await GeminiAssistantService.askWeatherAssistant(
        question: "ماذا أرتدي اليوم؟",
        weatherData: fullWeather,
      );
      expect(replyClothing.contains("ملابس") || replyClothing.contains("درجة الحرارة"), isTrue);

      final replyRain = await GeminiAssistantService.askWeatherAssistant(
        question: "هل هناك أمطار؟",
        weatherData: fullWeather,
      );
      expect(replyRain.isNotEmpty, isTrue);
    });
  });
}
