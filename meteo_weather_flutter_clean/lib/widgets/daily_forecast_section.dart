import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../theme/app_theme.dart';
import 'animated_weather_icon.dart';

class DailyForecastSection extends StatelessWidget {
  final List<DailyForecast> dailyList;

  const DailyForecastSection({
    super.key,
    required this.dailyList,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_month, size: 18, color: AppTheme.secondary),
              SizedBox(width: 8),
              Text(
                "التوقعات لـ 16 يوماً القادمة",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dailyList.length,
            separatorBuilder: (_, __) => const Divider(color: AppTheme.borderLight, height: 16),
            itemBuilder: (context, index) {
              final day = dailyList[index];
              return Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      day.dayLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  AnimatedWeatherIcon(
                    condition: day.conditionType,
                    isDay: true,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  if (day.precipitationProb > 10)
                    Text(
                      "${day.precipitationProb}%",
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    const SizedBox(width: 25),
                  const Spacer(),
                  Text(
                    "${day.minTempCelsius.toInt()}°",
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Temperature Range Bar
                  Container(
                    width: 80,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF38BDF8),
                          Color(0xFFFBBF24),
                          Color(0xFFF97316),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${day.maxTempCelsius.toInt()}°",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
