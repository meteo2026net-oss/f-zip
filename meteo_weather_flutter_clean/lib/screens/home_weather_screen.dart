import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../services/weather_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_dashboard_sheet.dart';
import '../widgets/animated_weather_icon.dart';
import '../widgets/audio_bulletin_section.dart';
import '../widgets/city_search_sheet.dart';
import '../widgets/customize_metrics_sheet.dart';
import '../widgets/daily_forecast_section.dart';
import '../widgets/gemini_chat_sheet.dart';
import '../widgets/hourly_forecast_section.dart';
import '../widgets/interactive_weather_map.dart';
import '../widgets/severe_weather_alert_banner.dart';
import '../widgets/syrian_stations_section.dart';
import '../widgets/weather_background.dart';
import '../widgets/weather_metrics_grid.dart';
import 'hourly_forecast_screen.dart';
import 'weather_trends_screen.dart';
import 'monthly_weather_screen.dart';
import 'weather_details_screen.dart';
import 'weather_maps_screen.dart';
import 'fieldclimate_screen.dart';

class HomeWeatherScreen extends StatefulWidget {
  const HomeWeatherScreen({super.key});

  @override
  State<HomeWeatherScreen> createState() => _HomeWeatherScreenState();
}

class _HomeWeatherScreenState extends State<HomeWeatherScreen> {
  final WeatherRepository _repository = WeatherRepository();

  CityLocation _selectedCity = WeatherRepository.defaultSyrianCities.first; // Damascus
  FullWeatherData? _weatherData;
  late List<SyrianWeatherStation> _stations;
  late AudioBulletinItem _bulletin;
  late List<MetricPreference> _metrics;
  bool _isLoading = true;
  String? _loadError;
  int _weatherRequestId = 0;

  @override
  void initState() {
    super.initState();
    _stations = _repository.getSyrianWeatherStations();
    _bulletin = _repository.getAudioBulletin();
    _metrics = _repository.getMetricPreferences();
    _initializeApp();
  }

  @override
  void dispose() {
    // Invalidate any pending weather request before releasing its HTTP client.
    _weatherRequestId++;
    _repository.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      await _repository.initializePreferences();
    } catch (_) {
      // The app can still run with in-memory defaults if local storage is unavailable.
    }
    if (!mounted) return;
    setState(() {
      _bulletin = _repository.getAudioBulletin();
      _metrics = _repository.getMetricPreferences();
    });
    await _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    final requestId = ++_weatherRequestId;
    setState(() { _isLoading = true; });
    final requestedCity = _selectedCity;
    try {
      final data = await _repository.getFullWeather(requestedCity);
      if (!mounted || requestId != _weatherRequestId) return;
      setState(() {
        _weatherData = data;
        _loadError = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || requestId != _weatherRequestId) return;
      setState(() {
        _weatherData = null;
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  void _onCitySelected(CityLocation city) {
    setState(() {
      _selectedCity = city;
      _weatherData = null;
      _loadError = null;
    });
    _loadWeatherData();
  }

  void _onStationSelected(SyrianWeatherStation station) {
    // Find or create city location from station
    final cityLoc = CityLocation(
      name: station.nameAr.replaceAll("محطة ", ""),
      country: "سوريا",
      latitude: station.latitude,
      longitude: station.longitude,
      admin1: station.governorate,
    );
    _onCitySelected(cityLoc);
  }

  void _openCitySearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CitySearchSheet(onCitySelected: _onCitySelected),
    );
  }

  void _openCustomizeMetrics() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomizeMetricsSheet(
        metrics: _metrics,
        onSave: (updated) async {
          setState(() {
            _metrics = updated;
          });
          await _repository.saveMetricPreferences(updated);
        },
      ),
    );
  }

  void _openFieldClimate() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anon = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (url.isEmpty || anon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يلزم إعداد SUPABASE_URL و SUPABASE_ANON_KEY عند البناء لتفعيل محطات FieldClimate.')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const FieldClimateScreen(supabaseUrl: url, anonKey: anon),
    ));
  }

  void _openWeatherMaps() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WeatherMapsScreen(
        latitude: _selectedCity.latitude,
        longitude: _selectedCity.longitude,
        cityName: _selectedCity.name,
      ),
    ));
  }

  void _showAboutApp() {
    showAboutDialog(
      context: context,
      applicationName: 'طقس المركز الوطني للأرصاد الجوية السورية',
      applicationVersion: 'إصدار تجريبي',
      applicationIcon: const Icon(Icons.cloud, color: AppTheme.primary, size: 36),
      children: const [
        Text('الاختصار: SCM Weather'),
        SizedBox(height: 8),
        Text('المبرمج: إبراهيم زينب'),
        SizedBox(height: 8),
        Text('تطبيق لعرض التوقعات والخرائط الجوية. البيانات من مصادرها الخارجية وليست بديلاً عن النشرات الرسمية.'),
      ],
    );
  }
  void _openGeminiChat() {
    if (_weatherData == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GeminiChatSheet(weatherData: _weatherData!),
    );
  }

  void _openAdminDashboard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdminDashboardSheet(
        repository: _repository,
        onAlertPublished: (alert) {
          setState(() {
            _weatherData?.alerts.insert(0, alert);
          });
        },
        onBulletinUpdated: () {
          setState(() {
            _bulletin = _repository.getAudioBulletin();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final condition = _weatherData?.current.conditionType ?? WeatherConditionType.CLEAR;
    final isDay = _weatherData?.current.isDay ?? true;

    return Scaffold(
      body: WeatherBackground(
        condition: condition,
        isDay: isDay,
        child: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: Colors.transparent,
                title: Row(
                  children: [
                    Image.asset(
                      'assets/app_weather_icon.jpg',
                      width: 28,
                      height: 28,
                      errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny, color: AppTheme.primary, size: 24),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "طقس سورية",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.sensors_outlined, color: AppTheme.secondary),
                    tooltip: 'محطات FieldClimate',
                    onPressed: _openFieldClimate,
                  ),
                  IconButton(
                    icon: const Icon(Icons.layers_outlined, color: AppTheme.primary),
                    tooltip: 'الخرائط الجوية',
                    onPressed: _openWeatherMaps,
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: AppTheme.textSecondary),
                    tooltip: 'حول التطبيق',
                    onPressed: _showAboutApp,
                  ),
                  // City selector button
                  InkWell(
                    onTap: _openCitySearch,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            _selectedCity.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.admin_panel_settings_outlined, color: AppTheme.secondary),
                    tooltip: "أدوات تجريبية محلية",
                    onPressed: _openAdminDashboard,
                  ),
                  IconButton(
                    icon: const Icon(Icons.schedule_outlined, color: AppTheme.secondary),
                    tooltip: "التوقعات الساعية",
                    onPressed: _weatherData == null ? null : () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => HourlyForecastScreen(weather: _weatherData!),
                      ));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_month_outlined, color: AppTheme.secondary),
                    tooltip: "ملخص الشهر الماضي",
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => MonthlyWeatherScreen(location: _selectedCity),
                      ));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.insights_outlined, color: AppTheme.tertiary),
                    tooltip: "اتجاهات التوقعات",
                    onPressed: _weatherData == null ? null : () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => WeatherTrendsScreen(weather: _weatherData!),
                      ));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.analytics_outlined, color: AppTheme.primary),
                    tooltip: "تفاصيل الطقس",
                    onPressed: _weatherData == null ? null : () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => WeatherDetailsScreen(weather: _weatherData!),
                      ));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
                    tooltip: "تحديث البيانات",
                    onPressed: _loadWeatherData,
                  ),
                ],
              ),
            ],
            body: _isLoading && _weatherData == null
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  )
                : _weatherData == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off, color: AppTheme.textMuted, size: 42),
                              const SizedBox(height: 12),
                              Text(
                                _loadError ?? "لا توجد بيانات طقس متاحة.",
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _loadWeatherData,
                                icon: const Icon(Icons.refresh),
                                label: const Text("إعادة المحاولة"),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                    onRefresh: _loadWeatherData,
                    color: AppTheme.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          // Hero Current Weather Card
                          _buildHeroWeatherCard(),

                          // Placeholder station locations (no live station feed connected)
                          SyrianStationsSection(
                            stations: _stations,
                            onStationSelected: _onStationSelected,
                          ),

                          // Automated weather indicators (not official alerts)
                          if (_weatherData != null && _weatherData!.alerts.isNotEmpty)
                            SevereWeatherAlertBanner(alerts: _weatherData!.alerts),

                          // Syrian Audio Bulletin Section (النشرة الصوتية)
                          AudioBulletinSection(bulletin: _bulletin),

                          // Hourly Forecast
                          if (_weatherData != null)
                            HourlyForecastSection(hourlyList: _weatherData!.hourlyList),

                          // Daily 16-day Forecast
                          if (_weatherData != null)
                            DailyForecastSection(dailyList: _weatherData!.dailyList),

                          // Environmental Metrics Grid (8 parameters)
                          if (_weatherData != null)
                            WeatherMetricsGrid(
                              weatherData: _weatherData!,
                              metrics: _metrics,
                              onCustomizeClicked: _openCustomizeMetrics,
                            ),

                          // Schematic station-location map (no live radar layer)
                          InteractiveWeatherMap(
                            stations: _stations,
                            onStationSelected: _onStationSelected,
                          ),

                          // Footer Info
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                            child: Column(
                              children: [
                                Text(
                                  _weatherData?.lastUpdated ?? "المركز الوطني للأرصاد الجوية والمناخ في الجمهورية العربية السورية",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "SCM Weather • المركز الوطني للأرصاد الجوية السورية • المبرمج: إبراهيم زينب",
                                  style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 60), // FAB spacing
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openGeminiChat,
        backgroundColor: AppTheme.primary,
        foregroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.auto_awesome),
        label: const Text(
          "اسأل مساعد الطقس المحلي",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeroWeatherCard() {
    final current = _weatherData?.current;
    if (current == null) return const SizedBox.shrink();

    final todayDaily = _weatherData?.dailyList.isNotEmpty == true ? _weatherData!.dailyList.first : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCity.name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedCity.admin1 ?? _selectedCity.country,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${current.temperatureCelsius.toInt()}",
                        style: const TextStyle(
                          fontSize: 68,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          height: 1.0,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          "°م",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                children: [
                  AnimatedWeatherIcon(
                    condition: current.conditionType,
                    isDay: current.isDay,
                    size: 80,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    current.conditionAr,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderLight),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeroSubMetric(
                label: "المحسوسة",
                value: "${current.apparentTemperatureCelsius.toInt()}°",
              ),
              _buildHeroSubMetric(
                label: "العظمى / الصغرى",
                value: todayDaily != null
                    ? "${todayDaily.maxTempCelsius.toInt()}° / ${todayDaily.minTempCelsius.toInt()}°"
                    : "--",
              ),
              _buildHeroSubMetric(
                label: "فرصة الأمطار",
                value: todayDaily == null || todayDaily.precipitationProb < 0
                    ? "—"
                    : "${todayDaily.precipitationProb}%",
              ),
              _buildHeroSubMetric(
                label: "سرعة الرياح",
                value: "${current.windSpeedKmh.toInt()} كم/س",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSubMetric({required String label, required String value}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
