import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  WeatherData? _currentWeather;
  List<FavoriteCity> _favorites = [];
  List<SearchHistory> _history = [];
  
  bool _isLoading = false;
  bool _isFirstLoad = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final favs = await StorageService.getFavorites();
      final hist = await StorageService.getHistory();
      
      // Clean up "Paris" entries from old history logs
      final cleanedHist = hist.where((item) => item.cityName.toLowerCase() != 'paris').toList();
      if (cleanedHist.length != hist.length) {
        await StorageService.saveHistory(cleanedHist.reversed.toList());
      }

      setState(() {
        _favorites = favs;
        _history = cleanedHist;
        _errorMessage = null;
      });
      
      _fetchFavoritesTemperatures();
      
      // Auto-load first favorite or first history city if available
      if (_isFirstLoad) {
        if (_favorites.isNotEmpty) {
          _searchCity(_favorites.first.cityName);
        } else if (_history.isNotEmpty) {
          _searchCity(_history.first.cityName);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Veriler yüklenirken hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isFirstLoad = false;
      });
    }
  }

  Future<void> _searchCity(String city) async {
    if (city.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Resolve city to latitude & longitude coordinates
      final coords = await ApiService.geocodeCity(city);
      final double lat = coords['latitude'];
      final double lon = coords['longitude'];
      final String actualName = coords['city_name'];
      final String country = coords['country'];

      // 2. Fetch weather info using those coordinates
      final weather = await ApiService.fetchWeather(lat, lon, actualName, country);
      
      // 3. Save search to local history logs
      final histEntry = SearchHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cityName: actualName,
        country: country,
        temperature: weather.temperature,
        weatherCode: weather.weatherCode,
        searchTime: DateTime.now(),
      );
      await StorageService.addHistory(histEntry);

      // Refresh history state list
      final hist = await StorageService.getHistory();
      final updatedFavorites = await StorageService.getFavorites();
      
      setState(() {
        _currentWeather = weather;
        _history = hist;
        _favorites = updatedFavorites;
        _suggestions = [];
        _searchController.text = ''; // Clear search text
      });
      _fetchFavoritesTemperatures();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentWeather == null) return;
    
    final isFav = _isCurrentCityFavorite();
    
    setState(() {
      _isLoading = true;
    });

    try {
      if (isFav) {
        final favId = _getFavoriteIdForCurrentCity();
        if (favId.isNotEmpty) {
          await StorageService.removeFavorite(favId);
        }
      } else {
        final favEntry = FavoriteCity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          cityName: _currentWeather!.cityName,
          country: _currentWeather!.country,
          latitude: _currentWeather!.latitude,
          longitude: _currentWeather!.longitude,
          temperature: _currentWeather!.temperature,
          addedAt: DateTime.now(),
        );
        await StorageService.addFavorite(favEntry);
      }
      
      // Refresh favorites state list
      final favs = await StorageService.getFavorites();
      setState(() {
        _favorites = favs;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İşlem başarısız: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _toTurkishLowerCase(String input) {
    return input
        .replaceAll('I', 'ı')
        .replaceAll('İ', 'i')
        .toLowerCase();
  }

  bool _isCurrentCityFavorite() {
    if (_currentWeather == null) return false;
    return _favorites.any((fav) =>
        _toTurkishLowerCase(fav.cityName) == _toTurkishLowerCase(_currentWeather!.cityName) &&
        _toTurkishLowerCase(fav.country) == _toTurkishLowerCase(_currentWeather!.country));
  }

  String _getFavoriteIdForCurrentCity() {
    if (_currentWeather == null) return '';
    final found = _favorites.firstWhere(
      (fav) =>
          _toTurkishLowerCase(fav.cityName) == _toTurkishLowerCase(_currentWeather!.cityName) &&
          _toTurkishLowerCase(fav.country) == _toTurkishLowerCase(_currentWeather!.country),
      orElse: () => FavoriteCity(id: '', cityName: '', country: '', latitude: 0, longitude: 0, temperature: 0.0, addedAt: DateTime.now()),
    );
    return found.id;
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code >= 1 && code <= 3) return Icons.wb_cloudy_rounded;
    if (code == 45 || code == 48) return Icons.blur_on_rounded;
    if (code >= 51 && code <= 57) return Icons.grain_rounded;
    if (code >= 61 && code <= 67) return Icons.umbrella_rounded;
    if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
    if (code >= 80 && code <= 82) return Icons.thunderstorm_rounded;
    if (code == 85 || code == 86) return Icons.severe_cold_rounded;
    if (code >= 95) return Icons.thunderstorm_rounded;
    return Icons.wb_sunny_rounded;
  }

  Color _getWeatherGlowColor(int code) {
    if (code == 0) return Colors.amber.withOpacity(0.08);
    if (code >= 1 && code <= 3) return Colors.blueGrey.withOpacity(0.08);
    if (code == 45 || code == 48) return Colors.purple.withOpacity(0.05);
    if (code >= 51 && code <= 67) return Colors.blue.withOpacity(0.08);
    if (code >= 71 && code <= 77) return Colors.cyan.withOpacity(0.06);
    if (code >= 80 && code <= 86) return Colors.teal.withOpacity(0.08);
    if (code >= 95) return Colors.deepPurple.withOpacity(0.08);
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    Widget buildSearchBox() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.text,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x0CFFFFFF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Icon(Icons.search_rounded, color: Color(0x80FFFFFF)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Şehir ara (örn. İstanbul, Paris)...',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: _onSearchChanged,
                      onSubmitted: _searchCity,
                    ),
                  ),
                  AnimatedSearchButton(
                    onPressed: () => _searchCity(_searchController.text),
                  ),
                ],
              ),
            ),
          ),
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xE61F1A30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x26FFFFFF)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(color: Color(0x0DFFFFFF), height: 1),
                itemBuilder: (context, index) {
                  final item = _suggestions[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    leading: const Icon(Icons.location_on_rounded, size: 16, color: Color(0x80FFFFFF)),
                    title: Text(
                      item['city_name'],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      item['country'],
                      style: const TextStyle(fontSize: 11, color: Color(0x80FFFFFF)),
                    ),
                    onTap: () => _selectSuggestion(item),
                  );
                },
              ),
            ),
          ],
        ],
      );
    }

    Widget buildFavoritesList() {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0x0CFFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star_rounded, color: Colors.amber[600], size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Favori Şehirler',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ],
            ),
            const Divider(color: Color(0x0DFFFFFF), height: 24),
            if (_favorites.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: Text(
                    'Henüz favori eklenmedi.',
                    style: TextStyle(color: Color(0x80FFFFFF), fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _favorites.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final fav = _favorites[index];
                  return InkWell(
                    onTap: () => _searchCity(fav.cityName),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0x05FFFFFF),
                        border: Border.all(color: const Color(0x08FFFFFF)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fav.cityName,
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                ),
                                Text(
                                  fav.country,
                                  style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${fav.temperature.round()}°C',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 16),
                            color: Colors.red[400],
                            visualDensity: VisualDensity.compact,
                            onPressed: () async {
                              await StorageService.removeFavorite(fav.id);
                              _loadData();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    }

    Widget buildHistoryList() {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0x0CFFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.history_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Son Aramalar',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ],
                ),
                if (_history.isNotEmpty)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _clearHistory,
                      child: Text(
                        'Temizle',
                        style: TextStyle(
                          color: Colors.red[300],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(color: Color(0x0DFFFFFF), height: 24),
            if (_history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: Text(
                    'Arama geçmişi temiz.',
                    style: TextStyle(color: Color(0x80FFFFFF), fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length > 5 ? 5 : _history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final hist = _history[index];
                  return InkWell(
                    onTap: () => _searchCity(hist.cityName),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0x05FFFFFF),
                        border: Border.all(color: const Color(0x08FFFFFF)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hist.cityName,
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                ),
                                Text(
                                  hist.country,
                                  style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${hist.temperature.round()}°C',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    }

    Widget buildMainDisplay() {
      if (_errorMessage != null) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0x0CFFFFFF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          padding: const EdgeInsets.all(40),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xE6FFFFFF), fontSize: 15),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Yeniden Dene'),
              ),
            ],
          ),
        );
      }

      if (_currentWeather == null) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0x0CFFFFFF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          padding: const EdgeInsets.all(40),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_sync_rounded, size: 80, color: Theme.of(context).colorScheme.tertiary),
              const SizedBox(height: 20),
              const Text(
                "GökYüzü'ne Hoş Geldiniz",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 10),
              const Text(
                'Şehir arayarak anlık ve detaylı hava durumu verilerini inceleyin, favorilerinize ekleyerek hızlıca ulaşın.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0x80FFFFFF), fontSize: 14, height: 1.5),
              ),
            ],
          ),
        );
      }

      final w = _currentWeather!;
      final isFav = _isCurrentCityFavorite();

      return Container(
        decoration: BoxDecoration(
          color: const Color(0x0CFFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x1AFFFFFF)),
          boxShadow: [
            BoxShadow(
              color: _getWeatherGlowColor(w.weatherCode),
              blurRadius: 30,
              offset: const Offset(0, -5),
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: City and Star Favorite Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.cityName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 14, color: Theme.of(context).colorScheme.tertiary),
                          const SizedBox(width: 4),
                          Text(
                            w.country,
                            style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 14, fontWeight: FontWeight.w300),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _toggleFavorite,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0x08FFFFFF),
                    side: const BorderSide(color: Color(0x10FFFFFF)),
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: Icon(
                    isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isFav ? Colors.amber[600] : const Color(0x80FFFFFF),
                    size: 24,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Temp and Icon Display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${w.temperature.round()}',
                      style: const TextStyle(fontSize: 54, fontWeight: FontWeight.w800, letterSpacing: -1),
                    ),
                    Text(
                      '°C',
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.w500, 
                        color: Theme.of(context).colorScheme.tertiary,
                        height: 2.0,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0x05FFFFFF),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0x0DFFFFFF), width: 1),
                      ),
                      child: Icon(
                        _getWeatherIcon(w.weatherCode),
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      w.weatherDescription,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Parameters as a single horizontal row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0x05FFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x06FFFFFF)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildCompactStatTile(Icons.thermostat_rounded, 'Hissedilen', '${w.apparentTemperature.round()}°C', Colors.indigo[400]!)),
                  Expanded(child: _buildCompactStatTile(Icons.water_drop_rounded, 'Nem', '${w.relativeHumidity}%', Colors.cyan[400]!)),
                  Expanded(child: _buildCompactStatTile(Icons.air_rounded, 'Rüzgar', '${w.windSpeed.round()} km/h', Colors.purple[400]!)),
                  Expanded(child: _buildCompactStatTile(Icons.umbrella_rounded, 'Yağış', '${w.precipitation.toStringAsFixed(1)} mm', Colors.blue[400]!)),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(color: Color(0x0DFFFFFF)),
            const SizedBox(height: 16),
            
            const Text(
              '1 Haftalık Hava Tahmini',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: w.dailyForecast.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0x08FFFFFF), height: 16),
              itemBuilder: (context, index) {
                final day = w.dailyForecast[index];
                final dayName = getTurkishDayName(day.date);
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        dayName,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Icon(
                            _getWeatherIcon(day.weatherCode),
                            size: 18,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ApiService.getWeatherDescription(day.weatherCode),
                              style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${day.tempMax.round()}° / ${day.tempMin.round()}°',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),
            const Divider(color: Color(0x0DFFFFFF)),
            const SizedBox(height: 12),

            // Footer Update Timestamp
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: Color(0x80FFFFFF)),
                const SizedBox(width: 6),
                Text(
                  'Veri Güncelleme Zamanı: ${DateFormat('HH:mm').format(w.fetchedAt)}',
                  style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 12, fontWeight: FontWeight.w300),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: width * 0.1,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.18),
              ),
              child: const SizedBox(),
            ),
          ),
          Positioned(
            bottom: -100,
            right: width * 0.1,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.18),
              ),
              child: const SizedBox(),
            ),
          ),

          // Main App Content Layout
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header App Bar Logo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_sync_rounded, size: 28, color: Theme.of(context).colorScheme.tertiary),
                          const SizedBox(width: 8),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, fontFamily: 'Outfit'),
                              children: [
                                const TextSpan(text: 'Gök'),
                                TextSpan(
                                  text: 'Yüzü',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Theme.of(context).colorScheme.tertiary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Modern, Anlık ve Detaylı Hava Durumu Takibi',
                        style: TextStyle(color: Color(0x80FFFFFF), fontSize: 13, fontWeight: FontWeight.w300),
                      ),
                      const SizedBox(height: 32),

                      // Responsive grid split
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 360,
                              child: Column(
                                children: [
                                  buildSearchBox(),
                                  const SizedBox(height: 16),
                                  buildFavoritesList(),
                                  const SizedBox(height: 16),
                                  buildHistoryList(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Stack(
                                children: [
                                  buildMainDisplay(),
                                  if (_isLoading)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Stack(
                          children: [
                            Column(
                              children: [
                                buildSearchBox(),
                                const SizedBox(height: 16),
                                buildMainDisplay(),
                                const SizedBox(height: 16),
                                buildFavoritesList(),
                                const SizedBox(height: 16),
                                buildHistoryList(),
                              ],
                            ),
                            if (_isLoading)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),
                          ],
                        ),

                      const SizedBox(height: 40),
                      const Text(
                        '© 2026 GökYüzü Weather App. Tüm Hakları Saklıdır. Open-Meteo ile güçlendirilmiştir.',
                        style: TextStyle(color: Color(0x66FFFFFF), fontSize: 11, fontWeight: FontWeight.w300),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatTile(IconData icon, String label, String value, Color iconColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0x80FFFFFF), fontSize: 10, fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }

  String getTurkishDayName(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      switch (date.weekday) {
        case DateTime.monday: return 'Pazartesi';
        case DateTime.tuesday: return 'Salı';
        case DateTime.wednesday: return 'Çarşamba';
        case DateTime.thursday: return 'Perşembe';
        case DateTime.friday: return 'Cuma';
        case DateTime.saturday: return 'Cumartesi';
        case DateTime.sunday: return 'Pazar';
      }
    } catch (_) {}
    return '';
  }

  Future<void> _fetchFavoritesTemperatures() async {
    if (_favorites.isEmpty) return;
    try {
      final List<FavoriteCity> updatedFavs = List<FavoriteCity>.from(_favorites);
      final futures = updatedFavs.map((fav) async {
        try {
          final weather = await ApiService.fetchWeather(fav.latitude, fav.longitude, fav.cityName, fav.country);
          return FavoriteCity(
            id: fav.id,
            cityName: fav.cityName,
            country: fav.country,
            latitude: fav.latitude,
            longitude: fav.longitude,
            temperature: weather.temperature,
            addedAt: fav.addedAt,
          );
        } catch (_) {
          return fav;
        }
      }).toList();

      final results = await Future.wait(futures);
      if (mounted) {
        setState(() {
          _favorites = results;
        });
        await StorageService.saveFavorites(results);
      }
    } catch (_) {}
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final trimmed = query.trim();
      if (trimmed.isNotEmpty) {
        try {
          final list = await ApiService.fetchSuggestions(trimmed);
          if (mounted) {
            setState(() {
              _suggestions = list;
            });
          }
        } catch (_) {}
      } else {
        if (mounted) {
          setState(() {
            _suggestions = [];
          });
        }
      }
    });
  }

  Future<void> _selectSuggestion(Map<String, dynamic> suggestion) async {
    setState(() {
      _suggestions = [];
      _searchController.clear();
      _isLoading = true;
      _errorMessage = null;
    });

    final String cityName = suggestion['city_name'];
    final String country = suggestion['country'];
    final double lat = suggestion['latitude'];
    final double lon = suggestion['longitude'];

    try {
      final weather = await ApiService.fetchWeather(lat, lon, cityName, country);
      
      final historyEntry = SearchHistory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        cityName: cityName,
        country: country,
        temperature: weather.temperature,
        weatherCode: weather.weatherCode,
        searchTime: DateTime.now(),
      );

      await StorageService.addHistory(historyEntry);
      
      final updatedHistory = await StorageService.getHistory();
      final updatedFavorites = await StorageService.getFavorites();

      if (mounted) {
        setState(() {
          _currentWeather = weather;
          _history = updatedHistory;
          _favorites = updatedFavorites;
        });
        _fetchFavoritesTemperatures();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearHistory() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await StorageService.clearHistory();
      final hist = await StorageService.getHistory();
      if (mounted) {
        setState(() {
          _history = hist;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class AnimatedSearchButton extends StatefulWidget {
  final VoidCallback onPressed;
  const AnimatedSearchButton({super.key, required this.onPressed});

  @override
  State<AnimatedSearchButton> createState() => _AnimatedSearchButtonState();
}

class _AnimatedSearchButtonState extends State<AnimatedSearchButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.9);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
