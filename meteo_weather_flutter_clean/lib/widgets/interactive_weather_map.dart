import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../theme/app_theme.dart';

/// Coordinate-based schematic only. The listed locations are illustrative,
/// not a verified inventory of operational MCNC observation stations.
class InteractiveWeatherMap extends StatelessWidget {
  final List<SyrianWeatherStation> stations;
  final Function(SyrianWeatherStation) onStationSelected;

  const InteractiveWeatherMap({
    super.key,
    required this.stations,
    required this.onStationSelected,
  });

  static const double _west = 35.4;
  static const double _east = 42.0;
  static const double _south = 32.2;
  static const double _north = 37.5;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.map_outlined, size: 20, color: AppTheme.tertiary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'مخطط إحداثي لمواقع الرصد',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                'مواقع توضيحية',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'تُرسم العلامات حسب إحداثيات المواقع المسجلة في التطبيق، ولا تؤكد وجود محطات عاملة أو اتصال مباشر بها.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 12),
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF172B49), Color(0xFF0B1424)],
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CoordinateGridPainter(),
                      ),
                    ),
                    for (final station in stations)
                      if (_isWithinPlot(station))
                        Align(
                          alignment: FractionalOffset(
                            ((station.longitude - _west) / (_east - _west))
                                .clamp(0.03, 0.97),
                            ((_north - station.latitude) / (_north - _south))
                                .clamp(0.05, 0.95),
                          ),
                          child: _StationMarker(
                            station: station,
                            onTap: () => onStationSelected(station),
                          ),
                        ),
                    Positioned(
                      left: 8,
                      bottom: 7,
                      child: _CoordinateLabel(
                        text: '35°–42° شرقاً',
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 7,
                      child: _CoordinateLabel(
                        text: '32°–38° شمالاً',
                      ),
                    ),
                    if (stations.isEmpty)
                      const Center(
                        child: Text(
                          'لا توجد مواقع لعرضها',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(Icons.touch_app_outlined,
                  size: 14, color: AppTheme.primary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'اضغط على أي علامة لعرض الطقس لذلك الموقع • ${stations.length} موقعاً مسجلاً',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Row(
            children: [
              Icon(Icons.radar, size: 13, color: AppTheme.textMuted),
              SizedBox(width: 5),
              Text(
                'لا توجد طبقة رادار أو صور أقمار صناعية حية',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isWithinPlot(SyrianWeatherStation station) =>
      station.longitude >= _west &&
      station.longitude <= _east &&
      station.latitude >= _south &&
      station.latitude <= _north;
}

class _StationMarker extends StatelessWidget {
  final SyrianWeatherStation station;
  final VoidCallback onTap;

  const _StationMarker({required this.station, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = station.nameAr
        .replaceFirst('محطة ', '')
        .replaceFirst(' الدولي', '')
        .replaceFirst(' البحرية', '')
        .replaceFirst(' المركزية', '')
        .replaceFirst(' الزراعية', '')
        .replaceFirst(' الميناء', '')
        .replaceFirst(' الأثرية', '')
        .replaceFirst(' السهل', '');
    return Tooltip(
      message: '$name • ${station.latitude.toStringAsFixed(3)}, ${station.longitude.toStringAsFixed(3)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.55),
                      blurRadius: 7,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xE6151C2C),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  name,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoordinateLabel extends StatelessWidget {
  final String text;
  const _CoordinateLabel({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xCC151C2C),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 8),
        ),
      );
}

class _CoordinateGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x3038BDF8)
      ..strokeWidth = 0.7;
    for (var i = 1; i < 5; i++) {
      final x = size.width * i / 5;
      final y = size.height * i / 5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final border = Paint()
      ..color = const Color(0x5538BDF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Offset.zero & size, border);
  }

  @override
  bool shouldRepaint(covariant _CoordinateGridPainter oldDelegate) => false;
}
