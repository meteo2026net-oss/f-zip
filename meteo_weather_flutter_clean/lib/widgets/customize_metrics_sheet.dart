import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../theme/app_theme.dart';

class CustomizeMetricsSheet extends StatefulWidget {
  final List<MetricPreference> metrics;
  final Future<void> Function(List<MetricPreference>) onSave;

  const CustomizeMetricsSheet({
    super.key,
    required this.metrics,
    required this.onSave,
  });

  @override
  State<CustomizeMetricsSheet> createState() => _CustomizeMetricsSheetState();
}

class _CustomizeMetricsSheetState extends State<CustomizeMetricsSheet> {
  late List<MetricPreference> _currentMetrics;

  @override
  void initState() {
    super.initState();
    _currentMetrics = widget.metrics.map((metric) => MetricPreference(
      id: metric.id,
      titleAr: metric.titleAr,
      isVisible: metric.isVisible,
      order: metric.order,
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "تخصيص بطاقات المؤشرات",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await widget.onSave(_currentMetrics);
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: const Color(0xFF0F172A),
                ),
                child: const Text("حفظ التغييرات"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "قم بتفعيل أو إلغاء تفعيل المؤشرات الظاهرة في الشاشة الرئيسية",
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: _currentMetrics.length,
              separatorBuilder: (_, __) => const Divider(color: AppTheme.borderLight),
              itemBuilder: (context, index) {
                final metric = _currentMetrics[index];
                return SwitchListTile(
                  title: Text(metric.titleAr, style: const TextStyle(color: AppTheme.textPrimary)),
                  value: metric.isVisible,
                  activeThumbColor: AppTheme.primary,
                  onChanged: (val) {
                    setState(() {
                      metric.isVisible = val;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
