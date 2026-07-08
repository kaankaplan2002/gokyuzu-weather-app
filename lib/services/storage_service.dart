import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather.dart';

class StorageService {
  static const String _favoritesKey = 'favorite_cities';
  static const String _historyKey = 'search_history';

  // Load favorite cities from SharedPreferences
  static Future<List<FavoriteCity>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? favsJson = prefs.getString(_favoritesKey);
    if (favsJson == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(favsJson);
      return decoded.map((item) => FavoriteCity.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  // Save favorite cities list to SharedPreferences
  static Future<void> saveFavorites(List<FavoriteCity> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(favorites.map((fav) => fav.toJson()).toList());
    await prefs.setString(_favoritesKey, encoded);
  }

  // Add a city to favorites
  static Future<void> addFavorite(FavoriteCity city) async {
    final favorites = await getFavorites();
    // Prevent duplicates
    final exists = favorites.any((fav) =>
        fav.cityName.toLowerCase() == city.cityName.toLowerCase() &&
        fav.country.toLowerCase() == city.country.toLowerCase());
    
    if (!exists) {
      favorites.add(city);
      await saveFavorites(favorites);
    }
  }

  // Remove a city from favorites by ID
  static Future<void> removeFavorite(String id) async {
    final favorites = await getFavorites();
    favorites.removeWhere((fav) => fav.id == id);
    await saveFavorites(favorites);
  }

  // Load search history from SharedPreferences
  static Future<List<SearchHistory>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? histJson = prefs.getString(_historyKey);
    if (histJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(histJson);
      final List<SearchHistory> list = decoded.map((item) => SearchHistory.fromJson(item)).toList();
      // Return reverse order (newest first)
      return list.reversed.toList();
    } catch (e) {
      return [];
    }
  }

  // Save search history list to SharedPreferences
  static Future<void> saveHistory(List<SearchHistory> history) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(history.map((hist) => hist.toJson()).toList());
    await prefs.setString(_historyKey, encoded);
  }

  static String _toTurkishLowerCase(String input) {
    return input
        .replaceAll('I', 'ı')
        .replaceAll('İ', 'i')
        .toLowerCase();
  }

  // Add a search entry to history logs, removing duplicates and capping at 5
  static Future<void> addHistory(SearchHistory entry) async {
    // Get history in original order to append
    final prefs = await SharedPreferences.getInstance();
    final String? histJson = prefs.getString(_historyKey);
    List<SearchHistory> list = [];
    if (histJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(histJson);
        list = decoded.map((item) => SearchHistory.fromJson(item)).toList();
      } catch (_) {}
    }

    // Check and remove duplicate city searches (case-insensitively with Turkish support)
    list.removeWhere((hist) =>
        _toTurkishLowerCase(hist.cityName) == _toTurkishLowerCase(entry.cityName) &&
        _toTurkishLowerCase(hist.country) == _toTurkishLowerCase(entry.country));

    // Limit history length to 5 items
    if (list.length >= 5) {
      list.removeAt(0); // Remove oldest
    }
    list.add(entry);
    await saveHistory(list);
  }

  // Clear search history logs from SharedPreferences
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
