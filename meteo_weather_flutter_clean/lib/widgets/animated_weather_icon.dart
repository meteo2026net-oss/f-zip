import 'package:flutter/material.dart';
import '../models/weather_models.dart';

class AnimatedWeatherIcon extends StatefulWidget {
  final WeatherConditionType condition;
  final bool isDay;
  final double size;

  const AnimatedWeatherIcon({
    super.key,
    required this.condition,
    this.isDay = true,
    this.size = 64.0,
  });

  @override
  State<AnimatedWeatherIcon> createState() => _AnimatedWeatherIconState();
}

class _AnimatedWeatherIconState extends State<AnimatedWeatherIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color iconColor;

    if (!widget.isDay) {
      switch (widget.condition) {
        case WeatherConditionType.CLEAR:
          iconData = Icons.nightlight_round;
          iconColor = const Color(0xFFE2E8F0);
          break;
        case WeatherConditionType.PARTLY_CLOUDY:
        case WeatherConditionType.CLOUDY:
          iconData = Icons.nights_stay;
          iconColor = const Color(0xFFCBD5E1);
          break;
        case WeatherConditionType.RAIN:
        case WeatherConditionType.HEAVY_RAIN:
        case WeatherConditionType.DRIZZLE:
          iconData = Icons.grain;
          iconColor = const Color(0xFF38BDF8);
          break;
        case WeatherConditionType.THUNDERSTORM:
          iconData = Icons.flash_on;
          iconColor = const Color(0xFFFACC15);
          break;
        case WeatherConditionType.SNOW:
          iconData = Icons.ac_unit;
          iconColor = const Color(0xFFE0F2FE);
          break;
        default:
          iconData = Icons.nightlight_round;
          iconColor = const Color(0xFFE2E8F0);
      }
    } else {
      switch (widget.condition) {
        case WeatherConditionType.CLEAR:
          iconData = Icons.wb_sunny;
          iconColor = const Color(0xFFFBBF24); // Sunny amber
          break;
        case WeatherConditionType.PARTLY_CLOUDY:
          iconData = Icons.cloud_queue;
          iconColor = const Color(0xFF93C5FD);
          break;
        case WeatherConditionType.CLOUDY:
        case WeatherConditionType.OVERCAST:
          iconData = Icons.cloud;
          iconColor = const Color(0xFF94A3B8);
          break;
        case WeatherConditionType.DRIZZLE:
        case WeatherConditionType.RAIN:
          iconData = Icons.water_drop;
          iconColor = const Color(0xFF38BDF8);
          break;
        case WeatherConditionType.HEAVY_RAIN:
          iconData = Icons.thunderstorm;
          iconColor = const Color(0xFF60A5FA);
          break;
        case WeatherConditionType.THUNDERSTORM:
          iconData = Icons.bolt;
          iconColor = const Color(0xFFF59E0B);
          break;
        case WeatherConditionType.SNOW:
          iconData = Icons.ac_unit;
          iconColor = const Color(0xFFE0F2FE);
          break;
        case WeatherConditionType.FOG:
          iconData = Icons.blur_on;
          iconColor = const Color(0xFF94A3B8);
          break;
        case WeatherConditionType.WINDY:
          iconData = Icons.air;
          iconColor = const Color(0xFF67E8F9);
          break;
      }
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 0.95 + (_controller.value * 0.1);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.3),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              iconData,
              size: widget.size * 0.85,
              color: iconColor,
            ),
          ),
        );
      },
    );
  }
}
