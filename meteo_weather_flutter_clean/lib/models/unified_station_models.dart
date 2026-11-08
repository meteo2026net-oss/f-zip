enum StationObservationSource {
  classic, manual, fieldclimate;
  static StationObservationSource parse(Object? value) => switch (value) {
    'classic' => StationObservationSource.classic,
    'manual' => StationObservationSource.manual,
    'fieldclimate' => StationObservationSource.fieldclimate,
    _ => throw FormatException('Unknown station observation source: $value'),
  };
  String get apiValue => name;
  String get labelAr => switch (this) {
    StationObservationSource.classic => 'كلاسيكي',
    StationObservationSource.manual => 'يدوي',
    StationObservationSource.fieldclimate => 'FieldClimate',
  };
}

enum StationObservationFilter {
  all, classic, manual, fieldclimate;
  bool accepts(StationObservationSource source) =>
      this == StationObservationFilter.all || name == source.apiValue;
}

class UnifiedWeatherStation {
  const UnifiedWeatherStation({
    required this.id, required this.code, required this.nameAr,
    required this.governorate, required this.latitude, required this.longitude,
  });
  final String id, code, nameAr, governorate;
  final double latitude, longitude;

  factory UnifiedWeatherStation.fromJson(Map<String, dynamic> json) {
    final lat = _requiredNumber(json, 'latitude');
    final lon = _requiredNumber(json, 'longitude');
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      throw const FormatException('Station coordinates are outside valid ranges');
    }
    return UnifiedWeatherStation(
      id: _requiredString(json, 'id'), code: _requiredString(json, 'code'),
      nameAr: _requiredString(json, 'name_ar'),
      governorate: (json['governorate'] as String?) ?? '',
      latitude: lat, longitude: lon,
    );
  }
}

class StationObservation {
  const StationObservation({
    required this.id, required this.stationId, required this.source,
    required this.sourceRecordId, required this.parameter, required this.value,
    required this.unit, required this.observedAt, required this.ingestedAt,
    required this.quality,
  });
  final String id, stationId, sourceRecordId, parameter, unit, quality;
  final StationObservationSource source;
  final num value;
  final DateTime observedAt, ingestedAt;

  factory StationObservation.fromJson(Map<String, dynamic> json) {
    final raw = json['value'];
    if (raw is! num) throw const FormatException('Observation value must be numeric');
    final observed = DateTime.tryParse(_requiredString(json, 'observed_at'));
    final ingested = DateTime.tryParse(_requiredString(json, 'ingested_at'));
    if (observed == null || ingested == null) {
      throw const FormatException('Observation timestamps must be valid ISO-8601 values');
    }
    return StationObservation(
      id: _requiredString(json, 'id'),
      stationId: _requiredString(json, 'station_id'),
      source: StationObservationSource.parse(json['source']),
      sourceRecordId: _requiredString(json, 'source_record_id'),
      parameter: _requiredString(json, 'parameter'),
      value: raw, unit: _requiredString(json, 'unit'),
      observedAt: observed.toUtc(), ingestedAt: ingested.toUtc(),
      quality: (json['quality'] as String?) ?? 'unverified',
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing required field: $key');
  }
  return value;
}

double _requiredNumber(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! num || !value.toDouble().isFinite) {
    throw FormatException('Missing or invalid numeric field: $key');
  }
  return value.toDouble();
}
