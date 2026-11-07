import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../theme/app_theme.dart';

class WeatherDetailsScreen extends StatelessWidget {
  final FullWeatherData weather;
  const WeatherDetailsScreen({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    final c = weather.current;
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطقس')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('الحالة الحالية'),
          _metricGrid([
            _Metric('الحرارة المحسوسة', '${c.apparentTemperatureCelsius.toStringAsFixed(1)} °م', Icons.thermostat),
            _Metric('الرطوبة', '${c.humidity}%', Icons.water_drop_outlined),
            _Metric('الضغط الجوي', '${c.pressureHpa.toStringAsFixed(0)} hPa', Icons.speed),
            _Metric('سرعة الرياح', '${c.windSpeedKmh.toStringAsFixed(1)} كم/س', Icons.air),
            _Metric('اتجاه الرياح', '${c.windDirectionDegree.toStringAsFixed(0)}°', Icons.explore_outlined),
            _Metric('الأشعة فوق البنفسجية', c.uvIndex.toStringAsFixed(1), Icons.wb_sunny_outlined),
            _Metric('الهطول الحالي', '${c.precipitationMm.toStringAsFixed(1)} مم', Icons.grain),
            _Metric('الرؤية الأفقية', c.visibilityMeters == null ? 'غير متاحة' : '${(c.visibilityMeters! / 1000).toStringAsFixed(1)} كم', Icons.visibility_outlined),
          ]),
          const SizedBox(height: 24),
          _sectionTitle('تغير الحرارة خلال الساعات القادمة'),
          _HourlyTemperatureChart(items: weather.hourlyList.take(24).toList()),
          const SizedBox(height: 24),
          _sectionTitle('جودة الهواء'),
          _infoCard('مؤشر جودة الهواء', '${weather.airQuality.aqi} — ${weather.airQuality.statusAr}', weather.airQuality.recommendationAr),
          const SizedBox(height: 12),
          _sectionTitle('حبوب اللقاح'),
          _infoCard('المستوى العام', weather.pollen.overallLevelAr,
            'الأعشاب: ${weather.pollen.grassLevelAr} • الأشجار: ${weather.pollen.treeLevelAr} • الأعشاب الضارة: ${weather.pollen.weedLevelAr}'),
          const SizedBox(height: 16),
          const Text('المصدر: Open-Meteo. جودة الهواء تقديرات نموذج CAMS وليست قياسات محطة أرضية.', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
  );

  Widget _metricGrid(List<_Metric> metrics) => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: metrics.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.65,
    ),
    itemBuilder: (context, index) {
      final m = metrics[index];
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(m.icon, color: AppTheme.primary, size: 20),
          Text(m.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
          Text(m.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ]),
      );
    },
  );

  Widget _infoCard(String title, String value, String detail) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(color: AppTheme.primary, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(detail, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
    ]),
  );
}

class _Metric {
  final String label, value;
  final IconData icon;
  const _Metric(this.label, this.value, this.icon);
}

class _HourlyTemperatureChart extends StatelessWidget {
  final List<HourlyForecast> items;
  const _HourlyTemperatureChart({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('لا تتوفر بيانات ساعية للرسم البياني.', style: TextStyle(color: AppTheme.textSecondary));
    }
    final values = items.map((e) => e.temperatureCelsius).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    return Container(
      height: 190,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderLight)),
      child: CustomPaint(
        painter: _TemperaturePainter(values: values, min: min, max: max, color: AppTheme.primary),
        child: Align(alignment: Alignment.bottomCenter, child: Text('${min.toStringAsFixed(0)}°م  —  ${max.toStringAsFixed(0)}°م', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
      ),
    );
  }
}

class _TemperaturePainter extends CustomPainter {
  final List<double> values;
  final double min, max;
  final Color color;
  _TemperaturePainter({required this.values, required this.min, required this.max, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final range = (max - min).abs() < 0.1 ? 1.0 : max - min;
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height * 0.78 - ((values[i] - min) / range) * size.height * 0.62;
      points.add(Offset(x, y));
    }
    final line = Paint()..color = color..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, line);
    final dot = Paint()..color = color..style = PaintingStyle.fill;
    for (final point in points) {
      canvas.drawCircle(point, 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _TemperaturePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.min != min || oldDelegate.max != max;
}
