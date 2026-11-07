import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../services/weather_repository.dart';
import '../theme/app_theme.dart';

class AdminDashboardSheet extends StatefulWidget {
  final WeatherRepository repository;
  final Function(SevereWeatherAlert) onAlertPublished;
  final VoidCallback onBulletinUpdated;

  const AdminDashboardSheet({
    super.key,
    required this.repository,
    required this.onAlertPublished,
    required this.onBulletinUpdated,
  });

  @override
  State<AdminDashboardSheet> createState() => _AdminDashboardSheetState();
}

class _AdminDashboardSheetState extends State<AdminDashboardSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // New Alert fields
  final TextEditingController _alertTitleController = TextEditingController();
  final TextEditingController _alertDescController = TextEditingController();
  final TextEditingController _alertInstructionController = TextEditingController();
  AlertSeverity _selectedSeverity = AlertSeverity.WARNING;

  // Bulletin fields
  final TextEditingController _bulletinTitleController = TextEditingController();
  final TextEditingController _bulletinScriptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final currentBulletin = widget.repository.getAudioBulletin();
    _bulletinTitleController.text = currentBulletin.title;
    _bulletinScriptController.text = currentBulletin.bulletinScriptAr;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _alertTitleController.dispose();
    _alertDescController.dispose();
    _alertInstructionController.dispose();
    _bulletinTitleController.dispose();
    _bulletinScriptController.dispose();
    super.dispose();
  }

  void _publishAlert() {
    if (_alertTitleController.text.trim().isEmpty) return;

    final newAlert = SevereWeatherAlert(
      id: "admin_${DateTime.now().millisecondsSinceEpoch}",
      titleAr: _alertTitleController.text.trim(),
      severity: _selectedSeverity,
      descriptionAr: _alertDescController.text.trim().isNotEmpty
          ? _alertDescController.text.trim()
          : "تنبيه تجريبي أُنشئ محلياً ولم يتم اعتماده أو إرساله رسمياً.",
      safetyInstructionsAr: _alertInstructionController.text.trim().isNotEmpty
          ? _alertInstructionController.text.trim()
          : "الالتزام بتوجيهات الدفاع المدني والابتعاد عن مجاري السيول والأماكن المكشوفة.",
      source: "إنشاء محلي - غير مرسل عبر CAP",
      validUntil: "ساري المفعول لمدة 12 ساعة",
    );

    widget.onAlertPublished(newAlert);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("أُضيف التنبيه إلى جلسة التطبيق الحالية فقط؛ لم يتم بثه إلى المستخدمين."),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _saveBulletin() async {
    await widget.repository.saveAdminAudioBulletin(
      _bulletinTitleController.text.trim(),
      _bulletinScriptController.text.trim(),
    );
    widget.onBulletinUpdated();
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("تم حفظ نص النشرة محلياً على هذا الجهاز."),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: AppTheme.secondary, size: 24),
                        SizedBox(width: 8),
                        Text(
                          "أدوات تجريبية محلية للطقس",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primary,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: AppTheme.textMuted,
                  tabs: const [
                    Tab(text: "تنبيه تجريبي محلي"),
                    Tab(text: "تسجيل النشرة الصوتية"),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: CAP Alerts
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "درجة خطورة التنبيه:",
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<AlertSeverity>(
                        initialValue: _selectedSeverity,
                        dropdownColor: AppTheme.surface,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppTheme.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: AlertSeverity.EMERGENCY, child: Text("طوارئ قصوى (أحمر)")),
                          DropdownMenuItem(value: AlertSeverity.WARNING, child: Text("تحذير جوي عاجل (برتقالي)")),
                          DropdownMenuItem(value: AlertSeverity.WATCH, child: Text("مراقبة جوية (أصفر)")),
                          DropdownMenuItem(value: AlertSeverity.ADVISORY, child: Text("تنويه وإرشاد (أزرق)")),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedSeverity = val);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _alertTitleController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: "عنوان التنبيه الجوي",
                          labelStyle: const TextStyle(color: AppTheme.textMuted),
                          filled: true,
                          fillColor: AppTheme.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _alertDescController,
                        maxLines: 3,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: "تفاصيل الحالة الجوية والمحافظات المشمولة",
                          labelStyle: const TextStyle(color: AppTheme.textMuted),
                          filled: true,
                          fillColor: AppTheme.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _alertInstructionController,
                        maxLines: 2,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: "إرشادات السلامة للمواطنين",
                          labelStyle: const TextStyle(color: AppTheme.textMuted),
                          filled: true,
                          fillColor: AppTheme.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _publishAlert,
                          icon: const Icon(Icons.broadcast_on_home),
                          label: const Text("إضافة التنبيه محلياً (دون بث)"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.alertEmergency,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab 2: Audio Bulletin
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _bulletinTitleController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: "عنوان النشرة الصوتية",
                          labelStyle: const TextStyle(color: AppTheme.textMuted),
                          filled: true,
                          fillColor: AppTheme.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _bulletinScriptController,
                        maxLines: 6,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: "نص النشرة الإذاعية (يقرؤه المذيع الآلي)",
                          labelStyle: const TextStyle(color: AppTheme.textMuted),
                          filled: true,
                          fillColor: AppTheme.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _saveBulletin,
                          icon: const Icon(Icons.record_voice_over),
                          label: const Text("حفظ نص النشرة على هذا الجهاز"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
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
