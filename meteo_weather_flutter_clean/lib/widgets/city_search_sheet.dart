import 'package:flutter/material.dart';
import '../models/weather_models.dart';
import '../services/open_meteo_service.dart';
import '../services/weather_repository.dart';
import '../theme/app_theme.dart';

class CitySearchSheet extends StatefulWidget {
  final Function(CityLocation) onCitySelected;

  const CitySearchSheet({
    super.key,
    required this.onCitySelected,
  });

  @override
  State<CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<CitySearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  final OpenMeteoService _apiService = OpenMeteoService();
  List<CityLocation> _searchResults = [];
  bool _isLoading = false;

  void _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final results = await _apiService.searchCities(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
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
          const Text(
            "البحث عن مدينة أو محافظة",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // Search Field
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: "ابحث عن دمشق، حلب، اللاذقية...",
              hintStyle: const TextStyle(color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged("");
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Quick Syrian Governorates Chips
          const Text(
            "المحافظات السورية الشائعة",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: WeatherRepository.defaultSyrianCities.take(6).map((city) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ActionChip(
                    label: Text(city.name),
                    labelStyle: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
                    backgroundColor: AppTheme.background,
                    side: const BorderSide(color: AppTheme.borderLight),
                    onPressed: () {
                      widget.onCitySelected(city);
                      Navigator.pop(context);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Results or Syrian Cities list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _searchResults.isNotEmpty
                    ? ListView.separated(
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const Divider(color: AppTheme.borderLight),
                        itemBuilder: (context, index) {
                          final city = _searchResults[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on, color: AppTheme.primary),
                            title: Text(city.name, style: const TextStyle(color: AppTheme.textPrimary)),
                            subtitle: Text("${city.admin1 ?? ''} - ${city.country}", style: const TextStyle(color: AppTheme.textMuted)),
                            onTap: () {
                              widget.onCitySelected(city);
                              Navigator.pop(context);
                            },
                          );
                        },
                      )
                    : ListView.separated(
                        itemCount: WeatherRepository.defaultSyrianCities.length,
                        separatorBuilder: (_, __) => const Divider(color: AppTheme.borderLight),
                        itemBuilder: (context, index) {
                          final city = WeatherRepository.defaultSyrianCities[index];
                          return ListTile(
                            leading: const Icon(Icons.pin_drop, color: AppTheme.secondary),
                            title: Text(city.name, style: const TextStyle(color: AppTheme.textPrimary)),
                            subtitle: Text("${city.admin1} - ${city.country}", style: const TextStyle(color: AppTheme.textMuted)),
                            onTap: () {
                              widget.onCitySelected(city);
                              Navigator.pop(context);
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
