import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../theme/app_theme.dart';

class WeatherMetricsGrid extends StatelessWidget {
  final FullWeatherData weatherData;
  final List<MetricPreference> metrics;
  final VoidCallback onCustomizeClicked;

  const WeatherMetricsGrid({
    super.key,
    required this.weatherData,
    required this.metrics,
    required this.onCustomizeClicked,
  });

  @override
  Widget build(BuildContext context) {
    final current = weatherData.current;
    final aqi = weatherData.airQuality;
    final pollen = weatherData.pollen;
    final visibleIds = metrics.where((metric) => metric.isVisible).map((metric) => metric.id).toSet();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.dashboard_customize_outlined, size: 18, color: AppTheme.tertiary),
                  SizedBox(width: 8),
                  Text(
                    "المؤشرات الجوية والبيئية",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onCustomizeClicked,
                icon: const Icon(Icons.tune, size: 16, color: AppTheme.primary),
                label: const Text(
                  "تخصيص",
                  style: TextStyle(fontSize: 12, color: AppTheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              if (visibleIds.contains("humidity")) _buildMetricCard(
                icon: Icons.water_drop_outlined,
                iconColor: const Color(0xFF38BDF8),
                title: "الرطوبة النسبية",
                value: "${current.humidity}%",
                subtitle: current.humidity > 70 ? "رطوبة مرتفعة" : (current.humidity < 30 ? "رطوبة منخفضة" : "رطوبة معتدلة"),
              ),
              if (visibleIds.contains("wind")) _buildMetricCard(
                icon: Icons.air,
                iconColor: const Color(0xFF67E8F9),
                title: "سرعة الرياح",
                value: "${current.windSpeedKmh.toInt()} كم/س",
                subtitle: "الاتجاه: ${_getWindDirection(current.windDirectionDegree)}",
              ),
              if (visibleIds.contains("pressure")) _buildMetricCard(
                icon: Icons.speed,
                iconColor: const Color(0xFFA78BFA),
                title: "الضغط الجوي",
                value: "${current.pressureHpa.toInt()} hPa",
                subtitle: "الضغط الجوي السطحي",
              ),
              if (visibleIds.contains("uv")) _buildMetricCard(
                icon: Icons.wb_sunny_outlined,
                iconColor: const Color(0xFFFBBF24),
                title: "مؤشر الأشعة (UV)",
                value: current.uvIndex.toStringAsFixed(1),
                subtitle: current.uvIndex >= 8 ? "مرتفع جداً" : (current.uvIndex >= 6 ? "مرتفع" : "تحقق من مستوى الحماية"),
              ),
              if (visibleIds.contains("air_quality")) _buildMetricCard(
                icon: Icons.eco_outlined,
                iconColor: aqi.aqi < 0 ? AppTheme.textMuted : (aqi.aqi <= 20 ? const Color(0xFF10B981) : (aqi.aqi <= 60 ? const Color(0xFFF59E0B) : AppTheme.alertWarning)),
                title: "جودة الهواء (تقدير نمذجي)",
                value: aqi.aqi < 0 ? "غير متاح" : "${aqi.aqi}",
                subtitle: aqi.aqi < 0 ? aqi.statusAr : "${aqi.statusAr} • تقدير CAMS وليس قياس محطة",
              ),
              if (visibleIds.contains("visibility")) _buildMetricCard(
                icon: Icons.remove_red_eye_outlined,
                iconColor: const Color(0xFF34D399),
                title: "مدى الرؤية",
                value: current.visibilityMeters == null
                    ? "غير متاح"
                    : "${(current.visibilityMeters! / 1000).toStringAsFixed(1)} كم",
                subtitle: current.visibilityMeters == null
                    ? "لا توجد قراءة للرؤية"
                    : "الرؤية الأفقية وفق بيانات التوقعات",
              ),
              if (visibleIds.contains("apparent_temperature")) _buildMetricCard(
                icon: Icons.thermostat_outlined,
                iconColor: const Color(0xFFF472B6),
                title: "الحرارة المحسوسة",
                value: "${current.apparentTemperatureCelsius.toInt()}°",
                subtitle: "الملموس الفعلي",
              ),
              if (visibleIds.contains("pollen")) _buildMetricCard(
                icon: Icons.grass,
                iconColor: const Color(0xFF4ADE80),
                title: "حبوب اللقاح",
                value: pollen.overallLevelAr,
                subtitle: pollen.overallLevelAr == "غير متاح" ? "لا تتوفر بيانات اللقاح من المصدر" : "تركيزات متاحة؛ دون تصنيف صحي",
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getWindDirection(double degree) {
    if (degree >= 337.5 || degree < 22.5) return "شمالية";
    if (degree >= 22.5 && degree < 67.5) return "شمالية شرقية";
    if (degree >= 67.5 && degree < 112.5) return "شرقية";
    if (degree >= 112.5 && degree < 157.5) return "جنوبية شرقية";
    if (degree >= 157.5 && degree < 202.5) return "جنوبية";
    if (degree >= 202.5 && degree < 247.5) return "جنوبية غربية";
    if (degree >= 247.5 && degree < 292.5) return "غربية";
    return "شمالية غربية";
  }
}
