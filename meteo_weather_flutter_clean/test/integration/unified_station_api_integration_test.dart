import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Opt-in black-box integration tests against a deployed MCNC API.
/// Configure the environment variables documented in docs/unified-stations-api.md.
/// These tests intentionally skip when no real test environment is configured.
void main() {
  const sourceNames = ['classic', 'manual', 'fieldclimate'];
  final baseUrl = Platform.environment['MCNC_API_BASE_URL'];
  final tenantAJwt = Platform.environment['MCNC_TENANT_A_JWT'];
  final tenantBJwt = Platform.environment['MCNC_TENANT_B_JWT'];
  final tenantAStationId = Platform.environment['MCNC_TENANT_A_STATION_ID'];

  final configured = [baseUrl, tenantAJwt, tenantBJwt, tenantAStationId]
      .every((value) => value != null && value.trim().isNotEmpty);

  group(
    'Deployed unified station API authorization and source integration',
    skip: configured ? false : 'Set MCNC_API_BASE_URL, MCNC_TENANT_A_JWT, MCNC_TENANT_B_JWT and MCNC_TENANT_A_STATION_ID to run against an isolated test deployment.',
    () {
      late Uri apiBase;
      late http.Client client;

      setUpAll(() {
        apiBase = Uri.parse(baseUrl!);
        client = http.Client();
      });

      tearDownAll(() => client.close());

      Uri observationsUri(String stationId, {String? source}) {
        final query = <String, String>{'limit': '100'};
        if (source != null) query['source'] = source;
        return apiBase.resolve('/api/v1/stations/$stationId/observations')
            .replace(queryParameters: query);
      }

      Map<String, String> auth(String jwt) => {
        HttpHeaders.authorizationHeader: 'Bearer $jwt',
        HttpHeaders.acceptHeader: 'application/json',
      };

      test('rejects requests without a user JWT', () async {
        final response = await client.get(
          observationsUri(tenantAStationId!),
          headers: {HttpHeaders.acceptHeader: 'application/json'},
        );
        expect([401, 403], contains(response.statusCode));
      });

      test('allows tenant A to read its own station observations', () async {
        final response = await client.get(
          observationsUri(tenantAStationId!),
          headers: auth(tenantAJwt!),
        );
        expect(response.statusCode, 200, reason: response.body);
        final rows = jsonDecode(response.body) as List<dynamic>;
        for (final row in rows) {
          expect((row as Map<String, dynamic>)['station_id'], tenantAStationId);
        }
      });

      test('prevents tenant B from reading tenant A station data (IDOR)', () async {
        final response = await client.get(
          observationsUri(tenantAStationId!),
          headers: auth(tenantBJwt!),
        );
        expect([403, 404], contains(response.statusCode),
            reason: 'Cross-tenant access must be denied without revealing station data.');
      });

      for (final source in sourceNames) {
        test('returns only $source observations when source filter is applied', () async {
          final response = await client.get(
            observationsUri(tenantAStationId!, source: source),
            headers: auth(tenantAJwt!),
          );
          expect(response.statusCode, 200, reason: response.body);
          final rows = jsonDecode(response.body) as List<dynamic>;
          for (final row in rows) {
            expect((row as Map<String, dynamic>)['source'], source);
            expect(row['station_id'], tenantAStationId);
          }
        });
      }
    },
  );
}
