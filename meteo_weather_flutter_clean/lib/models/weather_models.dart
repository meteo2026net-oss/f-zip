enum WeatherConditionType {
  CLEAR,
  PARTLY_CLOUDY,
  CLOUDY,
  OVERCAST,
  FOG,
  DRIZZLE,
  RAIN,
  HEAVY_RAIN,
  THUNDERSTORM,
  SNOW,
  WINDY,
}

enum AlertSeverity {
  ADVISORY,
  WATCH,
  WARNING,
  EMERGENCY,
}

class SyrianWeatherStation {
  final String id;
  final String nameAr;
  final String governorate;
  final double latitude;
  final double longitude;
  final double temperatureCelsius;
  final int humidity;
  final double pressureHpa;
  final double windSpeedKmh;
  final String conditionAr;
  final WeatherConditionType conditionType;
  final bool isOnline;
  final String lastReadingTime;

  SyrianWeatherStation({
    required this.id,
    required this.nameAr,
    required this.governorate,
    required this.latitude,
    required this.longitude,
    required this.temperatureCelsius,
    required this.humidity,
    required this.pressureHpa,
    required this.windSpeedKmh,
    required this.conditionAr,
    required this.conditionType,
    this.isOnline = false,
    this.lastReadingTime = "لا توجد بيانات مباشرة",
  });
}

class SevereWeatherAlert {
  final String id;
  final String titleAr;
  final AlertSeverity severity;
  final String descriptionAr;
  final String safetyInstructionsAr;
  final String source;
  final String validUntil;

  SevereWeatherAlert({
    required this.id,
    required this.titleAr,
    required this.severity,
    required this.descriptionAr,
    required this.safetyInstructionsAr,
    required this.source,
    required this.validUntil,
  });
}

class CapAlertItem {
  final String identifier;
  final String sender;
  final String sentTimestamp;
  final String status;
  final String msgType;
  final String scope;
  final String eventAr;
  final AlertSeverity severity;
  final String urgency;
  final String certainty;
  final String areaDescAr;
  final String descriptionAr;
  final String instructionAr;
  final String expires;

  CapAlertItem({
    required this.identifier,
    this.sender = "MCNC.SY.CAP@meteo.gov.sy",
    required this.sentTimestamp,
    this.status = "Actual",
    this.msgType = "Alert",
    this.scope = "Public",
    required this.eventAr,
    required this.severity,
    this.urgency = "Immediate",
    this.certainty = "Observed",
    required this.areaDescAr,
    required this.descriptionAr,
    required this.instructionAr,
    required this.expires,
  });
}

class AudioBulletinItem {
  final String id;
  final String title;
  final String dateFormatted;
  final int durationSec;
  final String announcerName;
  final String bulletinScriptAr;

  AudioBulletinItem({
    required this.id,
    required this.title,
    required this.dateFormatted,
    required this.durationSec,
    required this.announcerName,
    required this.bulletinScriptAr,
  });
}

class CityLocation {
  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final bool isFavorite;
  final String? admin1;
  final String? countryCode;

  CityLocation({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.isFavorite = false,
    this.admin1,
    this.countryCode,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'country': country,
    'latitude': latitude,
    'longitude': longitude,
    'isFavorite': isFavorite,
    'admin1': admin1,
    'countryCode': countryCode,
  };

  factory CityLocation.fromJson(Map<String, dynamic> json) => CityLocation(
    name: json['name'] as String,
    country: json['country'] as String? ?? 'سوريا',
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    isFavorite: json['isFavorite'] as bool? ?? false,
    admin1: json['admin1'] as String?,
    countryCode: json['countryCode'] as String?,
  );
}

class CurrentWeather {
  final String time;
  final double temperatureCelsius;
  final double apparentTemperatureCelsius;
  final int humidity;
  final bool isDay;
  final double precipitationMm;
  final int weatherCode;
  final double pressureHpa;
  final double windSpeedKmh;
  final double windDirectionDegree;
  final double uvIndex;
  final double? visibilityMeters;
  final String conditionAr;
  final WeatherConditionType conditionType;

  CurrentWeather({
    required this.time,
    required this.temperatureCelsius,
    required this.apparentTemperatureCelsius,
    required this.humidity,
    required this.isDay,
    required this.precipitationMm,
    required this.weatherCode,
    required this.pressureHpa,
    required this.windSpeedKmh,
    required this.windDirectionDegree,
    required this.uvIndex,
    this.visibilityMeters,
    required this.conditionAr,
    required this.conditionType,
  });
}

class HourlyForecast {
  final String time;
  final String hourLabel;
  final double temperatureCelsius;
  final int weatherCode;
  final int precipitationProb;
  final int humidity;
  final double windSpeedKmh;
  final WeatherConditionType conditionType;
  final bool isDay;

  HourlyForecast({
    required this.time,
    required this.hourLabel,
    required this.temperatureCelsius,
    required this.weatherCode,
    required this.precipitationProb,
    required this.humidity,
    required this.windSpeedKmh,
    required this.conditionType,
    this.isDay = true,
  });
}

class DailyForecast {
  final String date;
  final String dayLabel;
  final int weatherCode;
  final double maxTempCelsius;
  final double minTempCelsius;
  final int precipitationProb;
  final String sunrise;
  final String sunset;
  final double uvIndexMax;
  final WeatherConditionType conditionType;

  DailyForecast({
    required this.date,
    required this.dayLabel,
    required this.weatherCode,
    required this.maxTempCelsius,
    required this.minTempCelsius,
    required this.precipitationProb,
    required this.sunrise,
    required this.sunset,
    required this.uvIndexMax,
    required this.conditionType,
  });
}

class AirQualityInfo {
  final int aqi;
  final String statusAr;
  final double pm25;
  final double pm10;
  final String recommendationAr;

  AirQualityInfo({
    required this.aqi,
    required this.statusAr,
    required this.pm25,
    required this.pm10,
    required this.recommendationAr,
  });
}

class PollenInfo {
  final String grassLevelAr;
  final String treeLevelAr;
  final String weedLevelAr;
  final String overallLevelAr;
  final bool alertActive;

  PollenInfo({
    required this.grassLevelAr,
    required this.treeLevelAr,
    required this.weedLevelAr,
    required this.overallLevelAr,
    required this.alertActive,
  });
}

class FullWeatherData {
  final CityLocation location;
  final CurrentWeather current;
  final List<HourlyForecast> hourlyList;
  final List<DailyForecast> dailyList;
  final AirQualityInfo airQuality;
  final PollenInfo pollen;
  final List<SevereWeatherAlert> alerts;
  final String lastUpdated;

  FullWeatherData({
    required this.location,
    required this.current,
    required this.hourlyList,
    required this.dailyList,
    required this.airQuality,
    required this.pollen,
    required this.alerts,
    required this.lastUpdated,
  });
}

class MetricPreference {
  final String id;
  final String titleAr;
  bool isVisible;
  int order;

  MetricPreference({
    required this.id,
    required this.titleAr,
    this.isVisible = true,
    required this.order,
  });
}

class ChatMessageItem {
  final String id;
  final String sender; // "user" or "gemini"
  final String text;
  final String timestamp;

  ChatMessageItem({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });
}
