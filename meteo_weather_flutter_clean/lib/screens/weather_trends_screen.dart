import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_weather_icon.dart';

class WeatherTrendsScreen extends StatelessWidget {
  final FullWeatherData weather;
  const WeatherTrendsScreen({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    final days = weather.dailyList;
    return Scaffold(
      appBar: AppBar(title: const Text('اتجاهات التوقعات')),
      body: days.isEmpty
          ? const Center(child: Text('لا تتوفر بيانات يومية كافية.',
              style: TextStyle(color: AppTheme.textSecondary)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOverview(days),
                const SizedBox(height: 18),
                _buildTemperaturePanel(days),
                const SizedBox(height: 16),
                _buildRainPanel(days),
                const SizedBox(height: 16),
                const Text(
                  'هذه اتجاهات توقعات الأيام المتاحة وليست سجلاً مناخياً تاريخياً أو قياسات مرصودة.',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 12),
                ...days.map(_dayRow),
              ],
            ),
    );
  }

  Widget _buildOverview(List<DailyForecast> days) {
    final high = days.map((d) => d.maxTempCelsius).reduce((a, b) => a > b ? a : b);
    final low = days.map((d) => d.minTempCelsius).reduce((a, b) => a < b ? a : b);
    final uv = days.map((d) => d.uvIndexMax).reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('نظرة عامة • ${weather.location.name}',
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _stat('أعلى عظمى', '${high.toStringAsFixed(0)}°م', Icons.thermostat)),
          Expanded(child: _stat('أدنى صغرى', '${low.toStringAsFixed(0)}°م', Icons.ac_unit)),
          Expanded(child: _stat('أعلى UV', uv.toStringAsFixed(1), Icons.wb_sunny_outlined)),
        ]),
        const SizedBox(height: 8),
        Text('عدد الأيام المعروضة: ${days.length}',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ]),
    );
  }

  Widget _stat(String label, String value, IconData icon) => Column(children: [
    Icon(icon, color: AppTheme.primary, size: 19),
    const SizedBox(height: 5),
    Text(value, style: const TextStyle(color: AppTheme.textPrimary,
      fontWeight: FontWeight.bold, fontSize: 17)),
    Text(label, textAlign: TextAlign.center,
      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
  ]);

  Widget _buildTemperaturePanel(List<DailyForecast> days) {
    return _panel(
      title: 'مسار درجات الحرارة',
      subtitle: 'العظمى والصغرى المتوقعة لكل يوم',
      child: SizedBox(height: 170,
        child: CustomPaint(
          painter: _TrendPainter(
            first: days.map((d) => d.maxTempCelsius).toList(),
            second: days.map((d) => d.minTempCelsius).toList(),
            firstColor: AppTheme.secondary,
            secondColor: AppTheme.primary,
          ),
          child: const SizedBox.expand(),
        )),
      footer: const [
        _Legend(color: AppTheme.secondary, label: 'العظمى'),
        SizedBox(width: 18),
        _Legend(color: AppTheme.primary, label: 'الصغرى'),
      ],
    );
  }

  Widget _buildRainPanel(List<DailyForecast> days) {
    return _panel(
      title: 'احتمال الهطول',
      subtitle: 'النسبة المتوقعة لكل يوم',
      child: SizedBox(
        height: 126,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: days.map((d) {
            final value = d.precipitationProb < 0 ? 0 : d.precipitationProb.clamp(0, 100);
            return Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text(d.precipitationProb < 0 ? '—' : '$value%',
                  style: const TextStyle(fontSize: 8, color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Container(height: 76 * value / 100 + 2,
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.8),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))),
              ]),
            ));
          }).toList(),
        ),
      ),
      footer: const [],
    );
  }

  Widget _panel({required String title, required String subtitle,
    required Widget child, required List<Widget> footer}) => Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: AppTheme.textPrimary,
          fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        const SizedBox(height: 14),
        child,
        if (footer.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(children: footer),
        ],
      ]),
    );

  Widget _dayRow(DailyForecast day) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: AppTheme.surface.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: AppTheme.borderLight)),
    child: Row(children: [
      Expanded(flex: 3, child: Text(day.dayLabel,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12))),
      AnimatedWeatherIcon(condition: day.conditionType, isDay: true, size: 25),
      const SizedBox(width: 8),
      Text('${day.minTempCelsius.toStringAsFixed(0)}°',
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      const SizedBox(width: 10),
      Text('${day.maxTempCelsius.toStringAsFixed(0)}°',
        style: const TextStyle(color: AppTheme.textPrimary,
          fontWeight: FontWeight.bold, fontSize: 13)),
      const Spacer(),
      Text(day.precipitationProb < 0 ? '—' : '${day.precipitationProb}%',
        style: const TextStyle(color: AppTheme.primary, fontSize: 11)),
    ]),
  );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
  ]);
}

class _TrendPainter extends CustomPainter {
  final List<double> first, second;
  final Color firstColor, secondColor;
  _TrendPainter({required this.first, required this.second,
    required this.firstColor, required this.secondColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (first.length < 2 || second.length != first.length) return;
    final all = [...first, ...second];
    final min = all.reduce((a, b) => a < b ? a : b);
    final max = all.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs() < 0.1 ? 1.0 : max - min;
    final grid = Paint()..color = AppTheme.borderLight..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    void drawSeries(List<double> values, Color color) {
      final path = Path();
      for (var i = 0; i < values.length; i++) {
        final x = size.width * i / (values.length - 1);
        final y = size.height - 8 - (values[i] - min) / range * (size.height - 16);
        if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
      }
      canvas.drawPath(path, Paint()..color = color..strokeWidth = 2.2
        ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    }
    drawSeries(first, firstColor);
    drawSeries(second, secondColor);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.first != first || oldDelegate.second != second;
}
