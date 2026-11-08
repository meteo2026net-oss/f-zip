import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Read-only FieldClimate browser. Configure values with --dart-define.
/// Never put FieldClimate OAuth credentials or Supabase service-role keys here.
class FieldClimateScreen extends StatefulWidget {
  const FieldClimateScreen({super.key, required this.supabaseUrl, required this.anonKey});
  final String supabaseUrl;
  final String anonKey;

  @override
  State<FieldClimateScreen> createState() => _FieldClimateScreenState();
}

class _FieldClimateScreenState extends State<FieldClimateScreen> {
  List<Map<String, dynamic>> stations = [];
  List<Map<String, dynamic>> readings = [];
  String? stationId;
  String group = 'hourly';
  bool loading = true;
  bool loadingReadings = false;
  String? error;

  Map<String, String> get headers => {
    'apikey': widget.anonKey,
    'Authorization': 'Bearer ${widget.anonKey}',
    'Accept': 'application/json',
  };

  Uri endpoint(String view, Map<String, String> query) {
    final base = widget.supabaseUrl.replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$base/rest/v1/$view').replace(queryParameters: query);
  }

  @override
  void initState() { super.initState(); loadStations(); }

  Future<void> loadStations() async {
    setState(() { loading = true; error = null; });
    try {
      final response = await http.get(endpoint('fieldclimate_public_stations', {
        'select': 'station_id,station_name,latitude,longitude,altitude_m,last_synced_at',
        'order': 'station_name.asc', 'limit': '500',
      }), headers: headers).timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) throw Exception('تعذر تحميل محطات FieldClimate (${response.statusCode})');
      final rows = (jsonDecode(response.body) as List).whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e)).toList();
      if (!mounted) return;
      setState(() {
        stations = rows; loading = false;
        stationId ??= rows.isEmpty ? null : rows.first['station_id']?.toString();
      });
      if (stationId != null) await loadReadings();
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> loadReadings() async {
    final id = stationId;
    if (id == null) return;
    setState(() { loadingReadings = true; error = null; });
    try {
      final response = await http.get(endpoint('fieldclimate_public_readings', {
        'select': 'station_id,station_name,recorded_at,group_name,measurements,latitude,longitude',
        'station_id': 'eq.$id', 'group_name': 'eq.$group',
        'order': 'recorded_at.desc', 'limit': '250',
      }), headers: headers).timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) throw Exception('تعذر تحميل القراءات (${response.statusCode})');
      final rows = (jsonDecode(response.body) as List).whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e)).toList();
      if (!mounted) return;
      setState(() { readings = rows; loadingReadings = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString(); loadingReadings = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('محطات FieldClimate'), actions: [
        IconButton(onPressed: loadStations, icon: const Icon(Icons.refresh), tooltip: 'تحديث'),
      ]),
      body: loading ? const Center(child: CircularProgressIndicator())
        : error != null && stations.isEmpty ? Center(child: Text(error!, textAlign: TextAlign.center))
        : stations.isEmpty ? const Center(child: Text('لا توجد محطات محفوظة حتى الآن'))
        : ListView(padding: const EdgeInsets.all(16), children: [
          DropdownButtonFormField<String>(
            value: stationId, isExpanded: true,
            decoration: const InputDecoration(labelText: 'اختر المحطة', border: OutlineInputBorder()),
            items: stations.map((s) {
              final id = s['station_id'].toString();
              return DropdownMenuItem(value: id, child: Text(s['station_name']?.toString() ?? id));
            }).toList(),
            onChanged: (v) { setState(() => stationId = v); loadReadings(); },
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'hourly', label: Text('ساعي')),
              ButtonSegment(value: 'daily', label: Text('يومي')),
            ],
            selected: {group},
            onSelectionChanged: (v) { setState(() => group = v.first); loadReadings(); },
          ),
          if (error != null) Padding(padding: const EdgeInsets.all(8), child: Text(error!, style: const TextStyle(color: Colors.red))),
          if (loadingReadings) const Center(child: CircularProgressIndicator())
          else if (readings.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('لا توجد قراءات لهذه المحطة والفترة')))
          else ...readings.map((r) => Card(child: ListTile(
            title: Text(r['recorded_at']?.toString() ?? ''),
            subtitle: Text(const JsonEncoder.withIndent('  ').convert(r['measurements'] ?? {}),
              maxLines: 10, overflow: TextOverflow.ellipsis),
          ))),
        ]),
    ),
  );
}
