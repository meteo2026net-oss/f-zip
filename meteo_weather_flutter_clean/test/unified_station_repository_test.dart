import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_meteo_weather/models/unified_station_models.dart';
import 'package:flutter_meteo_weather/services/unified_station_repository.dart';

Map<String, dynamic> observation({
  required String id,
  required String source,
  required String sourceRecordId,
  required num value,
  String stationId = 'station-1',
}) => {
  'id': id,
  'station_id': stationId,
  'source': source,
  'source_record_id': sourceRecordId,
  'parameter': 'air_temperature',
  'value': value,
  'unit': '°C',
  'observed_at': '2026-11-08T04:00:00+03:00',
  'ingested_at': '2026-11-08T04:05:00Z',
  'quality': 'checked',
};

void main() {
  group('Unified station source model', () {
    test('parses all three source types distinctly', () {
      expect(StationObservationSource.parse('classic'), StationObservationSource.classic);
      expect(StationObservationSource.parse('manual'), StationObservationSource.manual);
      expect(StationObservationSource.parse('fieldclimate'), StationObservationSource.fieldclimate);
      expect(() => StationObservationSource.parse('forecast'), throwsFormatException);
    });

    test('preserves same-time conflicts from all three sources', () {
      final rows = [
        StationObservation.fromJson(observation(id: '1', source: 'classic', sourceRecordId: 'c-1', value: 19)),
        StationObservation.fromJson(observation(id: '2', source: 'manual', sourceRecordId: 'm-1', value: 20)),
        StationObservation.fromJson(observation(id: '3', source: 'fieldclimate', sourceRecordId: 'f-1', value: 21)),
      ];
      expect(rows, hasLength(3));
      expect(rows.map((row) => row.value), [19, 20, 21]);
      expect(rows.map((row) => row.source).toSet(), StationObservationSource.values.toSet());
      expect(rows.map((row) => row.observedAt.toUtc()).toSet(), hasLength(1));
    });

    test('normalizes observation timestamps to UTC', () {
      final row = StationObservation.fromJson(
        observation(id: '1', source: 'manual', sourceRecordId: 'm-1', value: 20),
      );
      expect(row.observedAt, DateTime.utc(2026, 11, 8, 1));
    });

    test('rejects unknown source and non-numeric readings', () {
      expect(
        () => StationObservation.fromJson(
          observation(id: '1', source: 'forecast', sourceRecordId: 'x', value: 1),
        ),
        throwsFormatException,
      );
      final bad = observation(id: '1', source: 'manual', sourceRecordId: 'm-1', value: 1);
      bad['value'] = '1';
      expect(() => StationObservation.fromJson(bad), throwsFormatException);
    });

    test('rejects invalid canonical station coordinates', () {
      expect(
        () => UnifiedWeatherStation.fromJson({
          'id': '1', 'code': 'MCNC-1', 'name_ar': 'دمشق',
          'latitude': 95, 'longitude': 36,
        }),
        throwsFormatException,
      );
    });
  });

  group('Unified station repository', () {
    test('uses authenticated bearer token and preserves all sources', () async {
      late http.Request captured;
      final rows = [
        observation(id: 'c', source: 'classic', sourceRecordId: 'c1', value: 18),
        observation(id: 'm', source: 'manual', sourceRecordId: 'm1', value: 19),
        observation(id: 'f', source: 'fieldclimate', sourceRecordId: 'f1', value: 20),
      ];
      final client = MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode(rows), 200);
      });
      final repository = UnifiedStationRepository(
        apiBaseUri: Uri.parse('https://api.example.test'),
        accessTokenProvider: () async => 'user-jwt',
        client: client,
      );

      final result = await repository.fetchObservations('station-1');
      expect(captured.headers['authorization'], 'Bearer user-jwt');
      expect(captured.url.path, '/api/v1/stations/station-1/observations');
      expect(result, hasLength(3));
      expect(result.map((row) => row.source).toSet(), StationObservationSource.values.toSet());
      repository.dispose();
    });

    test('applies source filter and does not return another station', () async {
      final client = MockClient((request) async => http.Response(jsonEncode([
        observation(id: 'm', source: 'manual', sourceRecordId: 'm1', value: 19),
        observation(id: 'f', source: 'fieldclimate', sourceRecordId: 'f1', value: 20),
        observation(id: 'other', source: 'manual', sourceRecordId: 'o1', value: 7, stationId: 'other'),
      ]), 200));
      final repository = UnifiedStationRepository(
        apiBaseUri: Uri.parse('https://api.example.test'),
        accessTokenProvider: () async => 'user-jwt',
        client: client,
      );
      final result = await repository.fetchObservations(
        'station-1',
        filter: StationObservationFilter.manual,
      );
      expect(result, hasLength(1));
      expect(result.single.source, StationObservationSource.manual);
      repository.dispose();
    });

    test('does not send unauthenticated requests when token is absent', () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return http.Response('[]', 200);
      });
      final repository = UnifiedStationRepository(
        apiBaseUri: Uri.parse('https://api.example.test'),
        accessTokenProvider: () async => null,
        client: client,
      );
      await expectLater(repository.fetchStations(), throwsStateError);
      expect(requests, 0);
      repository.dispose();
    });

    test('rejects unauthorized API responses', () async {
      final client = MockClient((request) async => http.Response('{}', 403));
      final repository = UnifiedStationRepository(
        apiBaseUri: Uri.parse('https://api.example.test'),
        accessTokenProvider: () async => 'expired-jwt',
        client: client,
      );
      await expectLater(repository.fetchStations(), throwsStateError);
      repository.dispose();
    });
  });
}
