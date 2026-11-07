import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_models.dart';
import '../services/open_meteo_service.dart';
import '../theme/app_theme.dart';

class MonthlyWeatherScreen extends StatefulWidget {
  final CityLocation location;
  const MonthlyWeatherScreen({super.key, required this.location});

  @override
  State<MonthlyWeatherScreen> createState() => _MonthlyWeatherScreenState();
}

class _MonthlyWeatherScreenState extends State<MonthlyWeatherScreen> {
  final OpenMeteoService _service = OpenMeteoService();
  late Future<List<Map<String, dynamic>>> _history;

  @override
  void initState() {
    super.initState();
    _history = _load();
  }

  Future<List<Map<String, dynamic>>> _load() => _service.fetchHistoricalMonth(
    latitude: widget.location.latitude,
    longitude: widget.location.longitude,
  );

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ملخص الشهر الماضي')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _history,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _emptyState();
        }
        final rows = snapshot.data!;
        final maxValues = rows.map((r) => r['maxTemp']).whereType<double>().toList();
        final minValues = rows.map((r) => r['minTemp']).whereType<double>().toList();
        final rainValues = rows.map((r) => r['precipitation']).whereType<double>().toList();
        final windValues = rows.map((r) => r['maxWind']).whereType<double>().toList();
        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: () async => setState(() { _history = _load(); }),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _summary(rows.length, maxValues, minValues, rainValues, windValues),
              const SizedBox(height: 16),
              _temperatureChart(rows),
              const SizedBox(height: 16),
              _rainPanel(rows),
              const SizedBox(height: 16),
              const Text('السجل اليومي',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 9),
              ...rows.reversed.map(_dayRow),
              const SizedBox(height: 12),
              const Text(
                'المصدر: Open-Meteo Historical Weather Archive. القيم تقديرات إعادة تحليل مناخي وليست قياسات مباشرة من محطة MCNC.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_outlined, size: 42, color: AppTheme.textMuted),
        const SizedBox(height: 12),
        const Text('تعذر تحميل السجل التاريخي حالياً. حاول مجدداً عند توفر الاتصال.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => setState(() { _history = _load(); }),
          icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة'),
        ),
      ]),
    ),
  );

  Widget _summary(int count, List<double> maxs, List<double> mins,
      List<double> rains, List<double> winds) {
    double? maxOf(List<double> values) => values.isEmpty ? null : values.reduce((a,b) => a > b ? a : b);
    double? minOf(List<double> values) => values.isEmpty ? null : values.reduce((a,b) => a < b ? a : b);
    final rainTotal = rains.isEmpty ? null : rains.fold<double>(0, (a,b) => a+b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ملخص آخر 30 يوماً • ${widget.location.name}',
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _metric('أعلى حرارة', maxOf(maxs), '°م', Icons.thermostat)),
          Expanded(child: _metric('أدنى حرارة', minOf(mins), '°م', Icons.ac_unit)),
          Expanded(child: _metric('مجموع المطر', rainTotal, 'مم', Icons.water_drop_outlined)),
        ]),
        const SizedBox(height: 12),
        Text('أعلى هبة رياح: ${maxOf(winds)?.toStringAsFixed(0) ?? '—'} كم/س  •  أيام البيانات: $count',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ]),
    );
  }

  Widget _metric(String label, double? value, String unit, IconData icon) => Column(children: [
    Icon(icon, color: AppTheme.primary, size: 19),
    const SizedBox(height: 5),
    Text(value == null ? '—' : '${value.toStringAsFixed(1)}$unit',
      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
    Text(label, textAlign: TextAlign.center,
      style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
  ]);

  Widget _temperatureChart(List<Map<String, dynamic>> rows) {
    final values = rows.map((r) => r['maxTemp']).whereType<double>().toList();
    if (values.length < 2) return const SizedBox.shrink();
    return _panel('الحرارة العظمى اليومية',
      SizedBox(height: 145, child: CustomPaint(
        painter: _MonthlyLinePainter(values), child: const SizedBox.expand(),
      )));
  }

  Widget _rainPanel(List<Map<String, dynamic>> rows) {
    final values = rows.map((r) => r['precipitation']).whereType<double>().toList();
    final max = values.isEmpty ? 0.0 : values.reduce((a,b) => a > b ? a : b);
    return _panel('الهطول اليومي',
      SizedBox(height: 100, child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values.map((v) => Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Container(
            height: max <= 0 ? 2 : (v / max * 90).clamp(2, 90).toDouble(),
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
          ),
        ))).toList(),
      )));
  }

  Widget _panel(String title, Widget child) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppTheme.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppTheme.borderLight)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      child,
    ]),
  );

  Widget _dayRow(Map<String, dynamic> row) {
    final date = DateTime.tryParse(row['date'] as String? ?? '');
    final label = date == null ? '—' : DateFormat('EEE d/M', 'ar').format(date);
    final max = row['maxTemp'] as double?;
    final min = row['minTemp'] as double?;
    final rain = row['precipitation'] as double?;
    final wind = row['maxWind'] as double?;
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppTheme.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight)),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 11))),
        Text('${min?.toStringAsFixed(0) ?? '—'}° / ${max?.toStringAsFixed(0) ?? '—'}°',
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11)),
        const SizedBox(width: 10),
        Text('${rain?.toStringAsFixed(1) ?? '—'} مم',
          style: const TextStyle(color: AppTheme.primary, fontSize: 10)),
        const SizedBox(width: 8),
        Text('${wind?.toStringAsFixed(0) ?? '—'} كم/س',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
      ]),
    );
  }
}

class _MonthlyLinePainter extends CustomPainter {
  final List<double> values;
  _MonthlyLinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce((a,b) => a < b ? a : b);
    final max = values.reduce((a,b) => a > b ? a : b);
    final range = (max-min).abs() < 0.1 ? 1.0 : max-min;
    final grid = Paint()..color = AppTheme.borderLight..strokeWidth = 1;
    for (var i=1; i<=3; i++) {
      final y=size.height*i/4;
      canvas.drawLine(Offset(0,y),Offset(size.width,y),grid);
    }
    final path=Path();
    for(var i=0;i<values.length;i++) {
      final x=size.width*i/(values.length-1);
      final y=size.height-8-(values[i]-min)/range*(size.height-16);
      if(i==0) { path.moveTo(x,y); } else { path.lineTo(x,y); }
    }
    canvas.drawPath(path,Paint()..color=AppTheme.secondary..strokeWidth=2.2
      ..style=PaintingStyle.stroke..strokeCap=StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _MonthlyLinePainter oldDelegate) => oldDelegate.values != values;
}
