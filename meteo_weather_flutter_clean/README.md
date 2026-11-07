# تطبيق طقس MCNC - نسخة Flutter (MCNC Weather) 🇸🇾🌦️

نسخة Flutter المطابقة تماماً لتطبيق الأندرويد الأصيل المبني بـ Kotlin و Jetpack Compose للمركز الوطني للأرصاد الجوية والمناخ في الجمهورية العربية السورية.

## 📱 متطلبات التشغيل
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0

## 🛠️ التثبيت والتشغيل السريع
```bash
# 1. تثبيت الحزم والمكتبات
flutter pub get

# 2. تشغيل التطبيق على الهاتف أو المحاكي أو المتصفح
flutter run
```

## 🏗️ هيكلية المشروع (Project Architecture)
```
flutter_meteo_weather/
├── lib/
│   ├── main.dart                      # نقطة البداية وإعدادات اللغة العربية والـ RTL
│   ├── theme/
│   │   └── app_theme.dart             # الألوان والتصميم الليلي Glassmorphic M3
│   ├── models/
│   │   └── weather_models.dart        # نماذج البيانات (محطات، تنبيهات، توقعات)
│   ├── services/
│   │   ├── open_meteo_service.dart    # الاتصال بـ API الأرصاد Open-Meteo
│   │   ├── weather_repository.dart    # مستودع البيانات والمحطات السورية
│   │   └── gemini_assistant_service.dart # مساعد الطقس الذكي
│   ├── widgets/
│   │   ├── weather_background.dart    # خلفية الطقس المتحركة
│   │   ├── animated_weather_icon.dart # أيقونات الطقس التفاعلية
│   │   ├── syrian_stations_section.dart # شبكة المحطات السورية الـ 13
│   │   ├── severe_weather_alert_banner.dart # تنبيهات الطوارئ CAP
│   │   ├── audio_bulletin_section.dart # النشرة الجوية الصوتية (TTS)
│   │   ├── hourly_forecast_section.dart # التوقعات الساعية 24 ساعة
│   │   ├── daily_forecast_section.dart # التوقعات اليومية 7 أيام
│   │   ├── weather_metrics_grid.dart  # مؤشرات الرطوبة والرياح والـ UV
│   │   ├── city_search_sheet.dart     # نافذة البحث عن المدن السورية
│   │   ├── customize_metrics_sheet.dart # تخصيص بطاقات المؤشرات
│   │   ├── gemini_chat_sheet.dart     # محادثة مساعد الطقس الذكي
│   │   ├── admin_dashboard_sheet.dart # لوحة تحكم وإصدار التنبيهات
│   │   └── interactive_weather_map.dart # خريطة الرادار والمحطات
│   └── screens/
│       └── home_weather_screen.dart   # الشاشة الرئيسية المنسقة
├── assets/
│   └── app_weather_icon.jpg           # أيقونة التطبيق الرسمية
└── pubspec.yaml                       # إعدادات الحزم والاعتماديات
```
