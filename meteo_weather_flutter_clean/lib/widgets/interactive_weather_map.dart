import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../theme/app_theme.dart';

class InteractiveWeatherMap extends StatelessWidget {
  final List<SyrianWeatherStation> stations;
  final Function(SyrianWeatherStation) onStationSelected;

  const InteractiveWeatherMap({
    super.key,
    required this.stations,
    required this.onStationSelected,
  });

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.map_outlined, size: 20, color: AppTheme.tertiary),
                  SizedBox(width: 8),
                  Text(
                    "مخطط مواقع محطات الرصد السورية",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                "مواقع توضيحية",
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stylized Syrian Weather Radar View
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderLight),
              gradient: const RadialGradient(
                center: Alignment(0.1, -0.2),
                radius: 0.8,
                colors: [
                  Color(0xFF1E3A8A), // Blue glow
                  Color(0xFF0F172A),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Grid overlay lines
                CustomPaint(
                  size: const Size(double.infinity, 200),
                  painter: _RadarGridPainter(),
                ),
                // Station Markers mapped roughly to coordinates in Syria
                _buildStationPin(context, stations.firstWhere((s) => s.id == "st_damascus", orElse: () => stations[0]), 0.45, 0.65),
                _buildStationPin(context, stations.firstWhere((s) => s.id == "st_aleppo", orElse: () => stations[1]), 0.48, 0.25),
                _buildStationPin(context, stations.firstWhere((s) => s.id == "st_latakia", orElse: () => stations[2]), 0.25, 0.38),
                _buildStationPin(context, stations.firstWhere((s) => s.id == "st_homs", orElse: () => stations[3]), 0.42, 0.52),
                _buildStationPin(context, stations.firstWhere((s) => s.id == "st_deir", orElse: () => stations[6]), 0.75, 0.45),
                _buildStationPin(context, stations.firstWhere((s) => s.id == "st_palmyra", orElse: () => stations[12]), 0.58, 0.55),

                // Radar Legend
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.radar, size: 12, color: AppTheme.primary),
                        SizedBox(width: 4),
                        Text(
                          "لا توجد طبقة رادار حية",
                          style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationPin(BuildContext context, SyrianWeatherStation station, double xPercent, double yPercent) {
    return Align(
      alignment: FractionalOffset(xPercent, yPercent),
      child: InkWell(
        onTap: () => onStationSelected(station),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primary, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.3),
                blurRadius: 6,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "${station.nameAr.replaceAll('محطة ', '')}",
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadarGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1538BDF8)
      ..strokeWidth = 1.0;

    // Draw range circles
    final center = Offset(size.width * 0.5, size.height * 0.5);
    canvas.drawCircle(center, 40, paint..style = PaintingStyle.stroke);
    canvas.drawCircle(center, 80, paint);
    canvas.drawCircle(center, 120, paint);

    // Cross lines
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), paint);
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
