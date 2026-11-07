import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../theme/app_theme.dart';
import 'animated_weather_icon.dart';

class HourlyForecastSection extends StatelessWidget {
  final List<HourlyForecast> hourlyList;

  const HourlyForecastSection({
    super.key,
    required this.hourlyList,
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
              Icon(Icons.access_time, size: 18, color: AppTheme.primary),
              SizedBox(width: 8),
              Text(
                "التوقعات الساعية (24 ساعة)",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: hourlyList.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final item = hourlyList[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.hourLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    AnimatedWeatherIcon(
                      condition: item.conditionType,
                      isDay: true,
                      size: 32,
                    ),
                    Text(
                      "${item.temperatureCelsius.toInt()}°",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.water_drop,
                          size: 10,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          "${item.precipitationProb}%",
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
