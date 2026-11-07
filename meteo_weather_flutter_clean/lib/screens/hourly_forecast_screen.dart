import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_weather_icon.dart';

class HourlyForecastScreen extends StatelessWidget {
  final FullWeatherData weather;

  const HourlyForecastScreen({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    final hours = weather.hourlyList;
    return Scaffold(
      appBar: AppBar(
        title: const Text('التوقعات الساعية'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Center(
              child: Text(weather.location.name,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ),
          ),
        ],
      ),
      body: hours.isEmpty
          ? const Center(child: Text('لا تتوفر بيانات ساعية حالياً.',
              style: TextStyle(color: AppTheme.textSecondary)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _summaryCard(hours),
                const SizedBox(height: 18),
                const Text('تفاصيل كل ساعة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
                const SizedBox(height: 10),
                ...hours.map((hour) => _hourCard(hour)),
                const SizedBox(height: 10),
                const Text(
                  'التوقعات مستمدة من نموذج Open-Meteo وقد تختلف عن القراءات الفعلية للمحطات.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
    );
  }

  Widget _summaryCard(List<HourlyForecast> hours) {
    final values = hours.map((e) => e.temperatureCelsius).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final rainHours = hours.where((e) => e.precipitationProb >= 30).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('ملخص الفترة المتاحة',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _summaryMetric('أعلى حرارة', '${max.toStringAsFixed(0)}°', Icons.thermostat)),
          Expanded(child: _summaryMetric('أدنى حرارة', '${min.toStringAsFixed(0)}°', Icons.ac_unit)),
          Expanded(child: _summaryMetric('ساعات احتمال المطر', '$rainHours', Icons.water_drop_outlined)),
        ]),
        const SizedBox(height: 18),
        SizedBox(
          height: 112,
          width: double.infinity,
          child: CustomPaint(painter: _HourlyChartPainter(values)),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(hours.first.hourLabel, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          Text(hours.last.hourLabel, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _summaryMetric(String label, String value, IconData icon) => Column(children: [
    Icon(icon, color: AppTheme.primary, size: 19),
    const SizedBox(height: 5),
    Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
    Text(label, textAlign: TextAlign.center,
      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
  ]);

  Widget _hourCard(HourlyForecast hour) {
    final time = hour.hourLabel.isEmpty ? hour.time : hour.hourLabel;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(children: [
        SizedBox(width: 54,
          child: Text(time, style: const TextStyle(color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600, fontSize: 12))),
        AnimatedWeatherIcon(condition: hour.conditionType, isDay: hour.isDay, size: 30),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${hour.temperatureCelsius.toStringAsFixed(0)}°م',
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          Text('رطوبة ${hour.humidity}%',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(children: [
            const Icon(Icons.water_drop, color: AppTheme.primary, size: 13),
            const SizedBox(width: 3),
            Text(hour.precipitationProb < 0 ? '—' : '${hour.precipitationProb}%',
              style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.air, color: AppTheme.textMuted, size: 13),
            const SizedBox(width: 3),
            Text('${hour.windSpeedKmh.toStringAsFixed(0)} كم/س',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
          ]),
        ]),
      ]),
    );
  }
}

class _HourlyChartPainter extends CustomPainter {
  final List<double> values;
  _HourlyChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    const horizontalInset = 4.0;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs() < 0.1 ? 1.0 : max - min;
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = horizontalInset + (size.width - horizontalInset * 2) * i / (values.length - 1);
      final y = size.height - 12 - ((values[i] - min) / range) * (size.height - 28);
      points.add(Offset(x, y));
    }
    final grid = Paint()..color = AppTheme.borderLight..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final line = Paint()..color = AppTheme.primary..strokeWidth = 2.5
      ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, line);
    final dots = Paint()..color = AppTheme.secondary;
    for (final point in points) {
      canvas.drawCircle(point, 2.6, dots);
    }
  }

  @override
  bool shouldRepaint(covariant _HourlyChartPainter oldDelegate) =>
      oldDelegate.values != values;
}
