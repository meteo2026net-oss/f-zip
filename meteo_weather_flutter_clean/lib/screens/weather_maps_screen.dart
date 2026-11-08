import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum WeatherMapLayer { temperature, wind, precipitation, pressure }

class WeatherMapsScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String cityName;

  const WeatherMapsScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.cityName,
  });

  @override
  State<WeatherMapsScreen> createState() => _WeatherMapsScreenState();
}

class _WeatherMapsScreenState extends State<WeatherMapsScreen> {
  WeatherMapLayer _layer = WeatherMapLayer.wind;
  int _forecastHour = 0;

  String get _layerPath {
    switch (_layer) {
      case WeatherMapLayer.temperature:
        return 'tmp2m';
      case WeatherMapLayer.wind:
        return 'wind';
      case WeatherMapLayer.precipitation:
        return 'precip';
      case WeatherMapLayer.pressure:
        return 'pressure';
    }
  }

  String get _layerTitle {
    switch (_layer) {
      case WeatherMapLayer.temperature:
        return 'درجة الحرارة';
      case WeatherMapLayer.wind:
        return 'سرعة الرياح';
      case WeatherMapLayer.precipitation:
        return 'الهطول';
      case WeatherMapLayer.pressure:
        return 'الضغط الجوي';
    }
  }

  String get _tileUrl {
    final validTime = DateTime.now().toUtc().add(Duration(hours: _forecastHour));
    final stamp = '${validTime.year.toString().padLeft(4, '0')}${validTime.month.toString().padLeft(2, '0')}${validTime.day.toString().padLeft(2, '0')}${validTime.hour.toString().padLeft(2, '0')}';
    return 'https://weathermaps.weatherapi.com/$_layerPath/tiles/$stamp/{z}/{x}/{y}.png';
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.latitude, widget.longitude);
    final selectedTime = DateTime.now().toUtc().add(Duration(hours: _forecastHour));
    return Scaffold(
      appBar: AppBar(
        title: const Text('الخرائط الجوية'),
        actions: [
          IconButton(
            tooltip: 'إعادة ضبط الموقع',
            icon: const Icon(Icons.my_location),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _layerButton(WeatherMapLayer.wind, 'الرياح', Icons.air),
                _layerButton(WeatherMapLayer.temperature, 'الحرارة', Icons.thermostat),
                _layerButton(WeatherMapLayer.precipitation, 'الأمطار', Icons.water_drop_outlined),
                _layerButton(WeatherMapLayer.pressure, 'الضغط', Icons.speed),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              key: ValueKey('${_layer.name}-$_forecastHour'),
              options: MapOptions(
                initialCenter: center,
                initialZoom: 5.8,
                minZoom: 3,
                maxZoom: 10,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.mcnc.weather.flutter_meteo_weather',
                ),
                TileLayer(
                  urlTemplate: _tileUrl,
                  userAgentPackageName: 'com.mcnc.weather.flutter_meteo_weather',
                  tileDisplay: const TileDisplay.fadeIn(duration: Duration(milliseconds: 180)),
                  errorTileCallback: (tile, error, stackTrace) {},
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                    TextSourceAttribution('Weather maps: WeatherAPI.com'),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 150,
                      height: 42,
                      child: IgnorePointer(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xDD102033),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white70),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(widget.cityName, style: const TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_layerTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(_forecastHour == 0 ? 'الآن' : '+$_forecastHour ساعة',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Slider(
                  value: _forecastHour.toDouble(),
                  min: 0,
                  max: 72,
                  divisions: 72,
                  label: _forecastHour == 0 ? 'الآن' : '+$_forecastHour س',
                  onChanged: (value) => setState(() => _forecastHour = value.round()),
                ),
                Text(
                  'وقت الخريطة: ${selectedTime.toLocal().toString().substring(0, 16)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                const Text(
                  'طبقات توقعية من WeatherAPI وليست قياسات مباشرة من محطات المركز. تتوفر حسب تغطية المصدر.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _layerButton(WeatherMapLayer value, String label, IconData icon) {
    final selected = _layer == value;
    return ChoiceChip(
      selected: selected,
      avatar: Icon(icon, size: 17),
      label: Text(label),
      onSelected: (_) => setState(() => _layer = value),
    );
  }
}