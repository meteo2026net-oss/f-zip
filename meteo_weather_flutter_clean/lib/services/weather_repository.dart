import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_models.dart';
import 'open_meteo_service.dart';

class WeatherDataUnavailableException implements Exception {
  final String message;
  const WeatherDataUnavailableException(this.message);
  @override
  String toString() => message;
}

class WeatherRepository {
  final OpenMeteoService _apiService;
  SharedPreferences? _prefs;

  WeatherRepository({
    OpenMeteoService? apiService,
    SharedPreferences? prefs,
  })  : _apiService = apiService ?? OpenMeteoService(),
        _prefs = prefs;

  Future<void> initializePreferences() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Default Syrian Cities
  static final List<CityLocation> defaultSyrianCities = [
    CityLocation(name: "دمشق", country: "سوريا", latitude: 33.5138, longitude: 36.2765, isFavorite: true, admin1: "محافظة دمشق"),
    CityLocation(name: "حلب", country: "سوريا", latitude: 36.2021, longitude: 37.1343, isFavorite: true, admin1: "محافظة حلب"),
    CityLocation(name: "حمص", country: "سوريا", latitude: 34.7324, longitude: 36.7137, isFavorite: true, admin1: "محافظة حمص"),
    CityLocation(name: "اللاذقية", country: "سوريا", latitude: 35.5317, longitude: 35.7915, isFavorite: true, admin1: "محافظة اللاذقية"),
    CityLocation(name: "طرطوس", country: "سوريا", latitude: 34.8890, longitude: 35.8866, isFavorite: false, admin1: "محافظة طرطوس"),
    CityLocation(name: "حماة", country: "سوريا", latitude: 35.1318, longitude: 36.7578, isFavorite: false, admin1: "محافظة حماة"),
    CityLocation(name: "دير الزور", country: "سوريا", latitude: 35.3333, longitude: 40.1500, isFavorite: false, admin1: "محافظة دير الزور"),
    CityLocation(name: "القامشلي", country: "سوريا", latitude: 37.0494, longitude: 41.2268, isFavorite: false, admin1: "محافظة الحسكة"),
    CityLocation(name: "السويداء", country: "سوريا", latitude: 32.7130, longitude: 36.5694, isFavorite: false, admin1: "محافظة السويداء"),
    CityLocation(name: "درعا", country: "سوريا", latitude: 32.6186, longitude: 36.1011, isFavorite: false, admin1: "محافظة درعا"),
    CityLocation(name: "إدلب", country: "سوريا", latitude: 35.9306, longitude: 36.6339, isFavorite: false, admin1: "محافظة إدلب"),
    CityLocation(name: "الرقة", country: "سوريا", latitude: 35.9556, longitude: 39.0078, isFavorite: false, admin1: "محافظة الرقة"),
    CityLocation(name: "تدمر", country: "سوريا", latitude: 34.5577, longitude: 38.2753, isFavorite: false, admin1: "بادية حمص"),
  ];

  // Placeholder station locations; live MCNC feeds are not connected.
  List<SyrianWeatherStation> getSyrianWeatherStations() {
    return [
      SyrianWeatherStation(
        id: "st_damascus",
        nameAr: "محطة دمشق الدولي",
        governorate: "محطة رئيسية - دمشق",
        latitude: 33.5138,
        longitude: 36.2765,
        temperatureCelsius: 24.0,
        humidity: 45,
        pressureHpa: 1014.2,
        windSpeedKmh: 14.0,
        conditionAr: "صافٍ ومشرق",
        conditionType: WeatherConditionType.CLEAR,
      ),
      SyrianWeatherStation(
        id: "st_aleppo",
        nameAr: "محطة حلب الدولي",
        governorate: "محطة رئيسية - حلب",
        latitude: 36.2021,
        longitude: 37.1343,
        temperatureCelsius: 21.0,
        humidity: 52,
        pressureHpa: 1013.8,
        windSpeedKmh: 16.5,
        conditionAr: "غائم جزئياً",
        conditionType: WeatherConditionType.PARTLY_CLOUDY,
      ),
      SyrianWeatherStation(
        id: "st_latakia",
        nameAr: "محطة اللاذقية البحرية",
        governorate: "محطة ساحلية - اللاذقية",
        latitude: 35.5317,
        longitude: 35.7915,
        temperatureCelsius: 26.0,
        humidity: 78,
        pressureHpa: 1012.5,
        windSpeedKmh: 22.0,
        conditionAr: "رذاذ خفيف",
        conditionType: WeatherConditionType.DRIZZLE,
      ),
      SyrianWeatherStation(
        id: "st_homs",
        nameAr: "محطة حمص المركزية",
        governorate: "محطة داخلية - حمص",
        latitude: 34.7324,
        longitude: 36.7137,
        temperatureCelsius: 23.0,
        humidity: 50,
        pressureHpa: 1013.0,
        windSpeedKmh: 18.0,
        conditionAr: "صافٍ",
        conditionType: WeatherConditionType.CLEAR,
      ),
      SyrianWeatherStation(
        id: "st_tartus",
        nameAr: "محطة طرطوس الميناء",
        governorate: "محطة ساحلية - طرطوس",
        latitude: 34.8890,
        longitude: 35.8866,
        temperatureCelsius: 25.0,
        humidity: 74,
        pressureHpa: 1012.8,
        windSpeedKmh: 19.5,
        conditionAr: "غائم جزئياً",
        conditionType: WeatherConditionType.PARTLY_CLOUDY,
      ),
      SyrianWeatherStation(
        id: "st_hama",
        nameAr: "محطة حماة الزراعية",
        governorate: "محطة داخلية - حماة",
        latitude: 35.1318,
        longitude: 36.7578,
        temperatureCelsius: 24.0,
        humidity: 48,
        pressureHpa: 1013.2,
        windSpeedKmh: 15.0,
        conditionAr: "صافٍ ومشرق",
        conditionType: WeatherConditionType.CLEAR,
      ),
      SyrianWeatherStation(
        id: "st_deir",
        nameAr: "محطة دير الزور",
        governorate: "محطة الشرق - دير الزور",
        latitude: 35.3333,
        longitude: 40.1500,
        temperatureCelsius: 28.0,
        humidity: 35,
        pressureHpa: 1011.5,
        windSpeedKmh: 12.0,
        conditionAr: "مشمس وجاف",
        conditionType: WeatherConditionType.CLEAR,
      ),
      SyrianWeatherStation(
        id: "st_qamishli",
        nameAr: "محطة القامشلي",
        governorate: "محطة الجزيرة - القامشلي",
        latitude: 37.0494,
        longitude: 41.2268,
        temperatureCelsius: 22.0,
        humidity: 42,
        pressureHpa: 1013.5,
        windSpeedKmh: 17.0,
        conditionAr: "صافٍ",
        conditionType: WeatherConditionType.CLEAR,
      ),
      SyrianWeatherStation(
        id: "st_sweida",
        nameAr: "محطة السويداء",
        governorate: "محطة الجبل - السويداء",
        latitude: 32.7130,
        longitude: 36.5694,
        temperatureCelsius: 19.0,
        humidity: 55,
        pressureHpa: 1015.0,
        windSpeedKmh: 13.0,
        conditionAr: "لطيف",
        conditionType: WeatherConditionType.PARTLY_CLOUDY,
      ),
      SyrianWeatherStation(
        id: "st_deraa",
        nameAr: "محطة درعا السهل",
        governorate: "محطة الجنوب - درعا",
        latitude: 32.6186,
        longitude: 36.1011,
        temperatureCelsius: 23.0,
        humidity: 46,
        pressureHpa: 1014.0,
        windSpeedKmh: 16.0,
        conditionAr: "صافٍ",
        conditionType: WeatherConditionType.CLEAR,
      ),
      SyrianWeatherStation(
        id: "st_idlib",
        nameAr: "محطة إدلب",
        governorate: "محطة الشمال - إدلب",
        latitude: 35.9306,
        longitude: 36.6339,
        temperatureCelsius: 21.0,
        humidity: 58,
        pressureHpa: 1013.1,
        windSpeedKmh: 14.0,
        conditionAr: "غائم جزئياً",
        conditionType: WeatherConditionType.PARTLY_CLOUDY,
      ),
      SyrianWeatherStation(
        id: "st_raqqa",
        nameAr: "محطة الرقة",
        governorate: "محطة الفرات - الرقة",
        latitude: 35.9556,
        longitude: 39.0078,
        temperatureCelsius: 27.0,
        humidity: 38,
        pressureHpa: 1012.0,
        windSpeedKmh: 15.5,
        conditionAr: "صافٍ",
        conditionType: WeatherConditionType.CLEAR,
      ),
      SyrianWeatherStation(
        id: "st_palmyra",
        nameAr: "محطة تدمر الأثرية",
        governorate: "محطة البادية - تدمر",
        latitude: 34.5577,
        longitude: 38.2753,
        temperatureCelsius: 29.0,
        humidity: 30,
        pressureHpa: 1011.0,
        windSpeedKmh: 18.5,
        conditionAr: "مشمس",
        conditionType: WeatherConditionType.CLEAR,
      ),
    ];
  }

  // Audio Bulletin
  AudioBulletinItem getAudioBulletin() {
    final title = _prefs?.getString("admin_bulletin_title") ??
        "نشرة تجريبية - غير معتمدة";
    final script = _prefs?.getString("admin_bulletin_script") ??
        "هذه نشرة تجريبية لواجهة التطبيق، وليست نشرة رسمية أو مبنية على بيانات الطقس الحالية. عند ربط مصدر النشرات المعتمد ستظهر هنا النشرة الموثوقة.";

    return AudioBulletinItem(
      id: "bulletin_mcnc_01",
      title: title,
      dateFormatted: "نص افتراضي - غير مسجل",
      durationSec: 54,
      announcerName: "قراءة آلية محلية",
      bulletinScriptAr: script,
    );
  }

  Future<void> saveAdminAudioBulletin(String title, String script) async {
    if (_prefs != null) {
      await _prefs!.setString("admin_bulletin_title", title);
      await _prefs!.setString("admin_bulletin_script", script);
    }
  }

  // Metric Preferences
  List<MetricPreference> getMetricPreferences() {
    final defaults = <MetricPreference>[
      MetricPreference(id: "humidity", titleAr: "الرطوبة النسبية", order: 1),
      MetricPreference(id: "wind", titleAr: "سرعة واتجاه الرياح", order: 2),
      MetricPreference(id: "pressure", titleAr: "الضغط الجوي", order: 3),
      MetricPreference(id: "uv", titleAr: "مؤشر الأشعة فوق البنفسجية", order: 4),
      MetricPreference(id: "air_quality", titleAr: "جودة الهواء والبيئة", order: 5),
      MetricPreference(id: "visibility", titleAr: "مدى الرؤية الأفقية", order: 6),
      MetricPreference(id: "apparent_temperature", titleAr: "الحرارة المحسوسة", order: 7),
      MetricPreference(id: "pollen", titleAr: "حبوب اللقاح والحساسية", order: 8),
    ];
    final raw = _prefs?.getString("metric_preferences");
    if (raw == null) return defaults;
    try {
      final stored = jsonDecode(raw) as List<dynamic>;
      final byId = <String, Map<String, dynamic>>{
        for (final item in stored)
          if (item is Map<String, dynamic> && item['id'] is String)
            item['id'] as String: item,
      };
      for (final metric in defaults) {
        final saved = byId[metric.id];
        if (saved == null) continue;
        metric.isVisible = saved['isVisible'] == true;
        metric.order = (saved['order'] as num?)?.toInt() ?? metric.order;
      }
      defaults.sort((a, b) => a.order.compareTo(b.order));
    } catch (_) {
      return defaults;
    }
    return defaults;
  }

  Future<void> saveMetricPreferences(List<MetricPreference> metrics) async {
    final payload = metrics.map((metric) => {
      "id": metric.id,
      "isVisible": metric.isVisible,
      "order": metric.order,
    }).toList();
    await _prefs?.setString("metric_preferences", jsonEncode(payload));
  }

  // WMO Code translation
  static WeatherConditionType mapWeatherCode(int code) {
    if (code == 0) return WeatherConditionType.CLEAR;
    if (code == 1 || code == 2) return WeatherConditionType.PARTLY_CLOUDY;
    if (code == 3) return WeatherConditionType.OVERCAST;
    if (code == 45 || code == 48) return WeatherConditionType.FOG;
    if (code >= 51 && code <= 57) return WeatherConditionType.DRIZZLE;
    if (code >= 61 && code <= 65) return WeatherConditionType.RAIN;
    if (code >= 71 && code <= 77) return WeatherConditionType.SNOW;
    if (code >= 80 && code <= 82) return WeatherConditionType.HEAVY_RAIN;
    if (code == 56 || code == 57) return WeatherConditionType.DRIZZLE;
    if (code == 66 || code == 67) return WeatherConditionType.HEAVY_RAIN;
    if (code == 85 || code == 86) return WeatherConditionType.SNOW;
    if (code >= 95 && code <= 99) return WeatherConditionType.THUNDERSTORM;
    return WeatherConditionType.CLOUDY;
  }

  static String getWeatherConditionText(int code, bool isDay) {
    switch (code) {
      case 0:
        return isDay ? "صافٍ ومشرق" : "سماء صافية";
      case 1:
      case 2:
        return "غائم جزئياً";
      case 3:
        return "غائم كلياً";
      case 45:
      case 48:
        return "ضباب وتدنٍ في الرؤية";
      case 51:
      case 53:
      case 55:
        return "رذاذ متفرق";
      case 56:
      case 57:
        return "رذاذ متجمد";
      case 61:
      case 63:
        return "أمطار معتدلة";
      case 65:
      case 66:
      case 67:
        return "أمطار غزيرة أو متجمدة";
      case 80:
      case 81:
      case 82:
        return "زخات مطر";
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return "تساقط ثلوج أو زخات ثلجية";
      case 95:
      case 96:
      case 99:
        return "عواصف رعدية";
      default:
        return "ظاهرة جوية غير مصنفة";
    }
  }

  // Full Weather fetcher
  Future<FullWeatherData> getFullWeather(CityLocation location) async {
    final forecastJson = await _apiService.fetchForecast(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    if (forecastJson == null) {
      throw const WeatherDataUnavailableException(
        "تعذر جلب بيانات الطقس من خدمة التوقعات.",
      );
    }

    final airQualityJson = await _apiService.fetchAirQuality(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    return _parseFullWeatherData(location, forecastJson, airQualityJson);
  }

  FullWeatherData _parseFullWeatherData(
    CityLocation location,
    Map<String, dynamic> forecast,
    Map<String, dynamic>? airQuality,
  ) {
    final currentObj = forecast['current'] as Map<String, dynamic>? ?? {};
    final hourlyObj = forecast['hourly'] as Map<String, dynamic>? ?? {};
    final dailyObj = forecast['daily'] as Map<String, dynamic>? ?? {};

    double requiredDouble(String key) {
      final value = currentObj[key];
      if (value is! num) {
        throw FormatException("Missing or invalid current.$key in forecast response.");
      }
      return value.toDouble();
    }

    int requiredInt(String key) => requiredDouble(key).toInt();

    final temp = requiredDouble('temperature_2m');
    final apparentTemp = requiredDouble('apparent_temperature');
    final humidity = requiredInt('relative_humidity_2m');
    final isDay = requiredInt('is_day') == 1;
    final precipMm = requiredDouble('precipitation');
    final weatherCode = requiredInt('weather_code');
    final pressure = requiredDouble('surface_pressure');
    final windSpeed = requiredDouble('wind_speed_10m');
    final windDir = requiredDouble('wind_direction_10m');
    final uv = requiredDouble('uv_index');

    final conditionType = mapWeatherCode(weatherCode);
    final conditionAr = getWeatherConditionText(weatherCode, isDay);

    final hourlyTimesForVisibility = (hourlyObj['time'] as List<dynamic>?) ?? [];
    final visibilityValues = (hourlyObj['visibility'] as List<dynamic>?) ?? [];
    double? currentVisibilityMeters;
    final currentTimeForVisibility = currentObj['time'] as String?;
    if (currentTimeForVisibility != null) {
      final visibilityIndex = hourlyTimesForVisibility.indexOf(currentTimeForVisibility);
      if (visibilityIndex >= 0 && visibilityIndex < visibilityValues.length) {
        final value = visibilityValues[visibilityIndex];
        if (value is num) currentVisibilityMeters = value.toDouble();
      }
    }

    final currentWeather = CurrentWeather(
      time: currentObj['time'] as String? ?? "الآن",
      temperatureCelsius: temp,
      apparentTemperatureCelsius: apparentTemp,
      humidity: humidity,
      isDay: isDay,
      precipitationMm: precipMm,
      weatherCode: weatherCode,
      pressureHpa: pressure,
      windSpeedKmh: windSpeed,
      windDirectionDegree: windDir,
      uvIndex: uv,
      visibilityMeters: currentVisibilityMeters,
      conditionAr: conditionAr,
      conditionType: conditionType,
    );

    // Hourly
    final hourlyTimes = (hourlyObj['time'] as List<dynamic>?) ?? [];
    final hourlyTemps = (hourlyObj['temperature_2m'] as List<dynamic>?) ?? [];
    final hourlyCodes = (hourlyObj['weather_code'] as List<dynamic>?) ?? [];
    final hourlyProbs = (hourlyObj['precipitation_probability'] as List<dynamic>?) ?? [];
    final hourlyHumids = (hourlyObj['relative_humidity_2m'] as List<dynamic>?) ?? [];
    final hourlyWinds = (hourlyObj['wind_speed_10m'] as List<dynamic>?) ?? [];

    final List<HourlyForecast> hourlyList = [];
    final currentTimeText = currentObj['time'] as String?;
    var firstFutureIndex = 0;
    if (currentTimeText != null) {
      try {
        final currentDateTime = DateTime.parse(currentTimeText);
        while (firstFutureIndex < hourlyTimes.length) {
          final hourDateTime = DateTime.parse(hourlyTimes[firstFutureIndex].toString());
          if (!hourDateTime.isBefore(currentDateTime)) break;
          firstFutureIndex++;
        }
      } catch (_) { firstFutureIndex = 0; }
    }
    final endIndex = (firstFutureIndex + 24).clamp(0, hourlyTimes.length).toInt();
    for (int i = firstFutureIndex; i < endIndex; i++) {
      final temperatureValue = i < hourlyTemps.length ? hourlyTemps[i] : null;
      final codeValue = i < hourlyCodes.length ? hourlyCodes[i] : null;
      if (temperatureValue is! num || codeValue is! num) continue;

      final tStr = hourlyTimes[i].toString();
      final hourLabel = tStr.contains('T') ? "${tStr.split('T')[1].split(':')[0]}:00" : "$i:00";
      final probabilityValue = i < hourlyProbs.length ? hourlyProbs[i] : null;
      final humidityValue = i < hourlyHumids.length ? hourlyHumids[i] : null;
      final windValue = i < hourlyWinds.length ? hourlyWinds[i] : null;
      final hCode = codeValue.toInt();
      hourlyList.add(
        HourlyForecast(
          time: tStr,
          hourLabel: hourLabel,
          temperatureCelsius: temperatureValue.toDouble(),
          weatherCode: hCode,
          precipitationProb: probabilityValue is num ? probabilityValue.toInt() : -1,
          humidity: humidityValue is num ? humidityValue.toInt() : -1,
          windSpeedKmh: windValue is num ? windValue.toDouble() : -1,
          conditionType: mapWeatherCode(hCode),
        ),
      );
    }

    // Daily
    final dailyTimes = (dailyObj['time'] as List<dynamic>?) ?? [];
    final dailyMaxTemps = (dailyObj['temperature_2m_max'] as List<dynamic>?) ?? [];
    final dailyMinTemps = (dailyObj['temperature_2m_min'] as List<dynamic>?) ?? [];
    final dailyCodes = (dailyObj['weather_code'] as List<dynamic>?) ?? [];
    final dailyProbs = (dailyObj['precipitation_probability_max'] as List<dynamic>?) ?? [];
    final dailySunrises = (dailyObj['sunrise'] as List<dynamic>?) ?? [];
    final dailySunsets = (dailyObj['sunset'] as List<dynamic>?) ?? [];
    final dailyUvs = (dailyObj['uv_index_max'] as List<dynamic>?) ?? [];

    const arabicWeekdays = ["الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت", "الأحد"];
    final List<DailyForecast> dailyList = [];
    final dCount = dailyTimes.length > 16 ? 16 : dailyTimes.length;
    for (int i = 0; i < dCount; i++) {
      final codeValue = i < dailyCodes.length ? dailyCodes[i] : null;
      final maxValue = i < dailyMaxTemps.length ? dailyMaxTemps[i] : null;
      final minValue = i < dailyMinTemps.length ? dailyMinTemps[i] : null;
      if (codeValue is! num || maxValue is! num || minValue is! num) continue;

      final dateValue = DateTime.tryParse(dailyTimes[i].toString());
      final dayLabel = i == 0
          ? "اليوم"
          : (i == 1
              ? "غداً"
              : (dateValue == null ? "اليوم ${i + 1}" : arabicWeekdays[dateValue.weekday - 1]));
      final probabilityValue = i < dailyProbs.length ? dailyProbs[i] : null;
      final sunriseValue = i < dailySunrises.length ? dailySunrises[i] : null;
      final sunsetValue = i < dailySunsets.length ? dailySunsets[i] : null;
      final uvValue = i < dailyUvs.length ? dailyUvs[i] : null;
      dailyList.add(
        DailyForecast(
          date: dailyTimes[i].toString(),
          dayLabel: dayLabel,
          weatherCode: codeValue.toInt(),
          maxTempCelsius: maxValue.toDouble(),
          minTempCelsius: minValue.toDouble(),
          precipitationProb: probabilityValue is num ? probabilityValue.toInt() : -1,
          sunrise: sunriseValue is String && sunriseValue.contains('T')
              ? sunriseValue.split('T')[1].substring(0, 5)
              : "--",
          sunset: sunsetValue is String && sunsetValue.contains('T')
              ? sunsetValue.split('T')[1].substring(0, 5)
              : "--",
          uvIndexMax: uvValue is num ? uvValue.toDouble() : -1,
          conditionType: mapWeatherCode(codeValue.toInt()),
        ),
      );
    }

    // Air Quality
    final aqCurrent = airQuality?['current'] as Map<String, dynamic>?;
    final aqiValue = aqCurrent?['european_aqi'] as num?;
    final hasAirQuality = aqiValue != null;
    final aqi = aqiValue?.toInt() ?? -1;
    final airQualityInfo = AirQualityInfo(
      aqi: aqi,
      statusAr: !hasAirQuality ? "بيانات جودة الهواء غير متاحة" : (aqi <= 20 ? "جيد" : (aqi <= 40 ? "مقبول" : (aqi <= 60 ? "متوسط" : (aqi <= 80 ? "ضعيف" : (aqi <= 100 ? "ضعيف جداً" : "مرتفع جداً"))))),
      pm25: (aqCurrent?['pm2_5'] as num?)?.toDouble() ?? -1,
      pm10: (aqCurrent?['pm10'] as num?)?.toDouble() ?? -1,
      recommendationAr: !hasAirQuality ? "تعذر الحصول على تقدير نمذجي لجودة الهواء." : "هذا تقدير نمذجي من بيانات CAMS عبر Open-Meteo، وليس قياساً من محطة أرضية.",
    );
    String pollenConcentration(num? value) {
      if (value == null) return "غير متاح";
      return "${value.toStringAsFixed(1)} حبة/م³";
    }
    final grassPollen = aqCurrent?['grass_pollen'] as num?;
    final alderPollen = aqCurrent?['alder_pollen'] as num?;
    final birchPollen = aqCurrent?['birch_pollen'] as num?;
    final weedPollen = aqCurrent?['ragweed_pollen'] as num?;
    final pollenValues = [grassPollen, alderPollen, birchPollen, weedPollen]
        .whereType<num>()
        .toList();
    final treePollen = alderPollen == null
        ? birchPollen
        : (birchPollen == null || alderPollen >= birchPollen ? alderPollen : birchPollen);
    final pollenInfo = PollenInfo(
      grassLevelAr: pollenConcentration(grassPollen),
      treeLevelAr: pollenConcentration(treePollen),
      weedLevelAr: pollenConcentration(weedPollen),
      overallLevelAr: pollenValues.isEmpty ? "غير متاح" : "تركيز متاح - دون تصنيف صحي",
      alertActive: false,
    );

    // Severe Alerts
    final alerts = _detectSevereAlerts(location, currentWeather, dailyList, aqi);

    return FullWeatherData(
      location: location,
      current: currentWeather,
      hourlyList: hourlyList,
      dailyList: dailyList,
      airQuality: airQualityInfo,
      pollen: pollenInfo,
      alerts: alerts,
      lastUpdated: "المصدر: Open-Meteo • وقت القراءة: ${currentWeather.time}",
    );
  }

  List<SevereWeatherAlert> _detectSevereAlerts(
    CityLocation location,
    CurrentWeather current,
    List<DailyForecast> daily,
    int aqi,
  ) {
    final List<SevereWeatherAlert> list = [];

    if (current.weatherCode >= 95 || current.conditionType == WeatherConditionType.THUNDERSTORM) {
      list.add(
        SevereWeatherAlert(
          id: "thunderstorm_${location.name}",
          titleAr: "مؤشر على نشاط رعدي في ${location.name}",
          severity: AlertSeverity.WARNING,
          descriptionAr: "تشير قيمة رمز الطقس المستلمة إلى نشاط رعدي في بيانات النموذج. لا تتضمن هذه القراءة وحدها تأكيداً للهبات الهابطة أو البَرَد.",
          safetyInstructionsAr: "ابتعد عن الأماكن المكشوفة وأعمدة الإنارة، وتجنب النزول للأودية وتجمعات المياه.",
          source: "تحليل آلي لبيانات Open-Meteo - ليس تحذيراً رسمياً",
          validUntil: "مؤشر آلي؛ تحقق من آخر تحديث رسمي",
        ),
      );
    }

    if (current.temperatureCelsius >= 38.0) {
      list.add(
        SevereWeatherAlert(
          id: "heatwave_${location.name}",
          titleAr: "مؤشر على حرارة مرتفعة في ${location.name}",
          severity: AlertSeverity.WATCH,
          descriptionAr: "تجاوزت الحرارة عتبة التطبيق البالغة 38°م. لا تمثل هذه المقارنة وحدها تحليلاً للمعدلات المناخية أو إعلاناً عن موجة حر رسمية.",
          safetyInstructionsAr: "تجنب التعرض المباشر لأشعة الشمس بين 11 صباحاً و 4 عصراً، واحرص على شرب السوائل بوفرة.",
          source: "تحليل آلي لبيانات Open-Meteo - ليس تحذيراً رسمياً",
          validUntil: "مؤشر آلي؛ تحقق من آخر تحديث رسمي",
        ),
      );
    }

    if (current.windSpeedKmh >= 40.0) {
      list.add(
        SevereWeatherAlert(
          id: "wind_${location.name}",
          titleAr: "مؤشر على سرعة رياح مرتفعة في ${location.name}",
          severity: AlertSeverity.ADVISORY,
          descriptionAr: "بلغت سرعة الرياح المقاسة ${current.windSpeedKmh.toInt()} كم/س. لا تتوفر هنا قراءة لهبات الرياح أو تركيز الغبار.",
          safetyInstructionsAr: "تثبيت الأجسام القابلة للتطاير والحذر عند القيادة على الطرق السريعة المفتوحة.",
          source: "تحليل آلي لبيانات Open-Meteo - ليس تحذيراً رسمياً",
          validUntil: "مؤشر آلي؛ تحقق من آخر تحديث رسمي",
        ),
      );
    }

    // Do not manufacture an official-looking stability bulletin when no threshold is met.
    return list;
  }


}
