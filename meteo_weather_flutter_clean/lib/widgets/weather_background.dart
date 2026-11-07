import 'package:flutter/material.dart';
import '../models/weather_models.dart';

class WeatherBackground extends StatelessWidget {
  final WeatherConditionType condition;
  final bool isDay;
  final Widget child;

  const WeatherBackground({
    super.key,
    required this.condition,
    required this.isDay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    List<Color> gradientColors;

    if (!isDay) {
      // Night gradient
      gradientColors = const [
        Color(0xFF020617), // Slate 950
        Color(0xFF0F172A), // Slate 900
        Color(0xFF1E1B4B), // Indigo 950
      ];
    } else {
      switch (condition) {
        case WeatherConditionType.CLEAR:
          gradientColors = const [
            Color(0xFF0284C7), // Sky 600
            Color(0xFF0369A1), // Sky 700
            Color(0xFF0F172A), // Slate 900
          ];
          break;
        case WeatherConditionType.PARTLY_CLOUDY:
        case WeatherConditionType.CLOUDY:
        case WeatherConditionType.OVERCAST:
          gradientColors = const [
            Color(0xFF334155), // Slate 700
            Color(0xFF1E293B), // Slate 800
            Color(0xFF0F172A), // Slate 900
          ];
          break;
        case WeatherConditionType.RAIN:
        case WeatherConditionType.HEAVY_RAIN:
        case WeatherConditionType.THUNDERSTORM:
          gradientColors = const [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
            Color(0xFF090D16),
          ];
          break;
        case WeatherConditionType.SNOW:
          gradientColors = const [
            Color(0xFF475569),
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ];
          break;
        default:
          gradientColors = const [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF020617),
          ];
      }
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      child: Stack(
        children: [
          // Background ambient circles
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDay ? const Color(0x2238BDF8) : const Color(0x15818CF8),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1038BDF8),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
