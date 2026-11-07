import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../theme/app_theme.dart';

class SevereWeatherAlertBanner extends StatefulWidget {
  final List<SevereWeatherAlert> alerts;

  const SevereWeatherAlertBanner({
    super.key,
    required this.alerts,
  });

  @override
  State<SevereWeatherAlertBanner> createState() => _SevereWeatherAlertBannerState();
}

class _SevereWeatherAlertBannerState extends State<SevereWeatherAlertBanner> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.alerts.isEmpty) return const SizedBox.shrink();

    final alert = widget.alerts.first;
    Color alertColor;
    String badgeText;

    switch (alert.severity) {
      case AlertSeverity.EMERGENCY:
        alertColor = AppTheme.alertEmergency;
        badgeText = "مؤشر آلي مرتفع";
        break;
      case AlertSeverity.WARNING:
        alertColor = AppTheme.alertWarning;
        badgeText = "تنبيه آلي";
        break;
      case AlertSeverity.WATCH:
        alertColor = AppTheme.alertWatch;
        badgeText = "مراقبة آلية";
        break;
      case AlertSeverity.ADVISORY:
        alertColor = AppTheme.alertAdvisory;
        badgeText = "معلومة آلية";
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: alertColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alertColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: alertColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                alert.severity == AlertSeverity.EMERGENCY || alert.severity == AlertSeverity.WARNING
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline,
                color: alertColor,
                size: 24,
              ),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: alertColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: alertColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.titleAr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Text(
              alert.validUntil,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
            trailing: Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: AppTheme.textSecondary,
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppTheme.borderLight),
                  const SizedBox(height: 6),
                  Text(
                    alert.descriptionAr,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "تعليمات السلامة: ${alert.safetyInstructionsAr}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "المصدر: ${alert.source}",
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
