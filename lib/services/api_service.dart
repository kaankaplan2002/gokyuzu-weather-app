import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

class ApiService {
  static String _normalizeQuery(String query) {
    return query
        .replaceAll('ı', 'i')
        .replaceAll('I', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ı'.toUpperCase(), 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c')
        .toLowerCase();
  }

  static String _translateCountry(String englishName) {
    final map = {
      'turkey': 'Türkiye',
      'france': 'Fransa',
      'germany': 'Almanya',
      'italy': 'İtalya',
      'spain': 'İspanya',
      'united kingdom': 'Birleşik Krallık',
      'united states': 'Amerika Birleşik Devletleri',
      'usa': 'Amerika Birleşik Devletleri',
      'russian federation': 'Rusya',
      'russia': 'Rusya',
      'greece': 'Yunanistan',
      'egypt': 'Mısır',
      'netherlands': 'Hollanda',
      'belgium': 'Belçika',
      'switzerland': 'İsviçre',
      'austria': 'Avusturya',
      'sweden': 'İsveç',
      'norway': 'Norveç',
      'denmark': 'Danimarka',
      'finland': 'Finlandiya',
      'portugal': 'Portekiz',
      'poland': 'Polonya',
      'ukraine': 'Ukrayna',
      'romania': 'Romanya',
      'bulgaria': 'Bulgaristan',
      'azerbaijan': 'Azerbaycan',
      'iran': 'İran',
      'iraq': 'Irak',
      'syria': 'Suriye',
      'saudi arabia': 'Suudi Arabistan',
      'united arab emirates': 'Birleşik Arap Emirlikleri',
      'qatar': 'Katar',
      'japan': 'Japonya',
      'china': 'Çin',
      'south korea': 'Güney Kore',
      'india': 'Hindistan',
      'brazil': 'Brezilya',
      'argentina': 'Arjantin',
      'canada': 'Kanada',
      'mexico': 'Meksika',
      'australia': 'Avustralya',
      'new zealand': 'Yeni Zelanda',
      'south africa': 'Güney Afrika',
      'morocco': 'Fas',
      'algeria': 'Cezayir',
      'tunisia': 'Tunus',
      'libya': 'Libya',
    };
    final key = englishName.trim().toLowerCase();
    return map[key] ?? englishName;
  }

  // Query Open-Meteo Geocoding API to resolve a city name to coordinates
  static Future<Map<String, dynamic>> geocodeCity(String cityName) async {
    final normalized = _normalizeQuery(cityName);
    final apiURL = 'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(normalized)}&count=1&language=tr&format=json';

    final response = await http.get(Uri.parse(apiURL));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic>? results = data['results'];

      if (results == null || results.isEmpty) {
        throw Exception('Şehir bulunamadı');
      }

      final result = results[0];
      return {
        'latitude': (result['latitude'] as num).toDouble(),
        'longitude': (result['longitude'] as num).toDouble(),
        'city_name': result['name'] ?? cityName,
        'country': _translateCountry(result['country'] ?? 'Bilinmeyen Ülke'),
      };
    } else {
      throw Exception('Şehir arama sorgusu başarısız oldu');
    }
  }

  // Get autocomplete suggestions as the user types, ordered by population popularity
  static Future<List<Map<String, dynamic>>> fetchSuggestions(String query) async {
    if (query.trim().isEmpty) return [];
    
    final normalized = _normalizeQuery(query);
    
    // For single letter queries, return the pre-defined popular cities local fallback
    if (normalized.length == 1) {
      final fallback = _singleLetterSuggestions[normalized];
      if (fallback != null) {
        return fallback;
      }
    }
    
    // Fetch 20 candidates to capture famous cities in the search mix
    final apiURL = 'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(normalized)}&count=20&language=tr&format=json';

    final response = await http.get(Uri.parse(apiURL));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic>? results = data['results'];

      if (results == null) {
        return [];
      }

      final List<Map<String, dynamic>> mapped = results.map((item) {
        return {
          'city_name': item['name'] ?? '',
          'country': _translateCountry(item['country'] ?? ''),
          'latitude': (item['latitude'] as num).toDouble(),
          'longitude': (item['longitude'] as num).toDouble(),
          'population': item['population'] != null ? (item['population'] as num).toInt() : 0,
        };
      }).toList();

      // Sort by population descending to rank popular cities first
      mapped.sort((a, b) => (b['population'] as int).compareTo(a['population'] as int));

      // Deduplicate results strictly by city_name to show only one entry per city name
      final seenNames = <String>{};
      final List<Map<String, dynamic>> uniqueSuggestions = [];
      for (final item in mapped) {
        final nameLower = item['city_name'].toLowerCase();
        if (!seenNames.contains(nameLower)) {
          seenNames.add(nameLower);
          uniqueSuggestions.add(item);
        }
      }

      return uniqueSuggestions.take(5).toList();
    } else {
      return [];
    }
  }

  // Fetch weather data for resolved coordinates
  static Future<WeatherData> fetchWeather(
    double lat,
    double lon,
    String cityName,
    String country,
  ) async {
    final apiURL = 'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min';

    final response = await http.get(Uri.parse(apiURL));

    if (response.statusCode == 200) {
      final Map<String, dynamic> wResp = jsonDecode(utf8.decode(response.bodyBytes));
      final current = wResp['current'];
      
      if (current == null) {
        throw Exception('Hava durumu verisi alınamadı');
      }

      final int code = current['weather_code'] ?? 0;
      final desc = getWeatherDescription(code);

      // Inject values to map to WeatherData.fromJson layout
      wResp['city_name'] = cityName;
      wResp['country'] = country;
      wResp['latitude'] = lat;
      wResp['longitude'] = lon;
      wResp['temperature'] = current['temperature_2m'];
      wResp['relative_humidity'] = current['relative_humidity_2m'];
      wResp['apparent_temperature'] = current['apparent_temperature'];
      wResp['precipitation'] = current['precipitation'];
      wResp['weather_code'] = code;
      wResp['weather_description'] = desc;
      wResp['wind_speed'] = current['wind_speed_10m'];
      wResp['time'] = current['time'] ?? '';
      wResp['fetched_at'] = DateTime.now().toIso8601String();

      return WeatherData.fromJson(wResp);
    } else {
      throw Exception('Hava durumu tahmini başarısız oldu');
    }
  }

  // Maps WMO Weather Interpretation Codes to user-friendly Turkish descriptions
  static String getWeatherDescription(int code) {
    switch (code) {
      case 0:
        return "Açık Gökyüzü";
      case 1:
        return "Çoğunlukla Açık";
      case 2:
        return "Parçalı Bulutlu";
      case 3:
        return "Bulutlu / Kapalı";
      case 45:
      case 48:
        return "Sisli";
      case 51:
      case 53:
      case 55:
        return "Hafif Çiseleme";
      case 56:
      case 57:
        return "Dondurucu Çiseleme";
      case 61:
        return "Hafif Yağmurlu";
      case 63:
        return "Orta Şiddette Yağmurlu";
      case 65:
        return "Şiddetli Yağmurlu";
      case 66:
      case 67:
        return "Dondurucu Yağmurlu";
      case 71:
        return "Hafif Karlı";
      case 73:
        return "Orta Şiddette Karlı";
      case 75:
        return "Şiddetli Karlı";
      case 77:
        return "Kar İnce Tane";
      case 80:
      case 81:
      case 82:
        return "Sağanak Yağışlı";
      case 85:
      case 86:
        return "Sağanak Kar Yağışlı";
      case 95:
        return "Gök Gürültülü Fırtına";
      case 96:
      case 99:
        return "Dolu Şiddetli Fırtına";
      default:
        return "Bilinmeyen Hava Durumu";
    }
  }

  static final Map<String, List<Map<String, dynamic>>> _singleLetterSuggestions = {
    'a': [
      {'city_name': 'Ankara', 'country': 'Türkiye', 'latitude': 39.93, 'longitude': 32.85},
      {'city_name': 'Amsterdam', 'country': 'Hollanda', 'latitude': 52.37, 'longitude': 4.89},
      {'city_name': 'Atina', 'country': 'Yunanistan', 'latitude': 37.98, 'longitude': 23.73},
      {'city_name': 'Antalya', 'country': 'Türkiye', 'latitude': 36.88, 'longitude': 30.70},
      {'city_name': 'Adana', 'country': 'Türkiye', 'latitude': 37.00, 'longitude': 35.32},
    ],
    'b': [
      {'city_name': 'Berlin', 'country': 'Almanya', 'latitude': 52.52, 'longitude': 13.40},
      {'city_name': 'Barcelona', 'country': 'İspanya', 'latitude': 41.38, 'longitude': 2.17},
      {'city_name': 'Bursa', 'country': 'Türkiye', 'latitude': 40.18, 'longitude': 29.06},
      {'city_name': 'Brüksel', 'country': 'Belçika', 'latitude': 50.85, 'longitude': 4.35},
      {'city_name': 'Boston', 'country': 'Amerika Birleşik Devletleri', 'latitude': 42.36, 'longitude': -71.05},
    ],
    'c': [
      {'city_name': 'Çanakkale', 'country': 'Türkiye', 'latitude': 40.15, 'longitude': 26.41},
      {'city_name': 'Chicago', 'country': 'Amerika Birleşik Devletleri', 'latitude': 41.87, 'longitude': -87.62},
      {'city_name': 'Cenevre', 'country': 'İsviçre', 'latitude': 46.20, 'longitude': 6.14},
      {'city_name': 'Çorum', 'country': 'Türkiye', 'latitude': 40.55, 'longitude': 34.96},
      {'city_name': 'Cidde', 'country': 'Suudi Arabistan', 'latitude': 21.54, 'longitude': 39.17},
    ],
    'd': [
      {'city_name': 'Dublin', 'country': 'İrlanda', 'latitude': 53.34, 'longitude': -6.26},
      {'city_name': 'Delhi', 'country': 'Hindistan', 'latitude': 28.61, 'longitude': 77.20},
      {'city_name': 'Diyarbakır', 'country': 'Türkiye', 'latitude': 37.91, 'longitude': 40.21},
      {'city_name': 'Doha', 'country': 'Katar', 'latitude': 25.28, 'longitude': 51.53},
      {'city_name': 'Denizli', 'country': 'Türkiye', 'latitude': 37.77, 'longitude': 29.08},
    ],
    'e': [
      {'city_name': 'Eskişehir', 'country': 'Türkiye', 'latitude': 39.77, 'longitude': 30.52},
      {'city_name': 'Edirne', 'country': 'Türkiye', 'latitude': 41.67, 'longitude': 26.55},
      {'city_name': 'Edinburgh', 'country': 'Birleşik Krallık', 'latitude': 55.95, 'longitude': -3.18},
      {'city_name': 'Elazığ', 'country': 'Türkiye', 'latitude': 38.68, 'longitude': 39.22},
      {'city_name': 'Erzurum', 'country': 'Türkiye', 'latitude': 39.90, 'longitude': 41.27},
    ],
    'f': [
      {'city_name': 'Frankfurt', 'country': 'Almanya', 'latitude': 50.11, 'longitude': 8.68},
      {'city_name': 'Floransa', 'country': 'İtalya', 'latitude': 43.76, 'longitude': 11.25},
      {'city_name': 'Fethiye', 'country': 'Türkiye', 'latitude': 36.62, 'longitude': 29.11},
      {'city_name': 'Fukuoka', 'country': 'Japonya', 'latitude': 33.59, 'longitude': 130.40},
      {'city_name': 'Fas', 'country': 'Fas', 'latitude': 34.03, 'longitude': -5.00},
    ],
    'g': [
      {'city_name': 'Gaziantep', 'country': 'Türkiye', 'latitude': 37.06, 'longitude': 37.38},
      {'city_name': 'Giresun', 'country': 'Türkiye', 'latitude': 40.91, 'longitude': 38.38},
      {'city_name': 'Glasgow', 'country': 'Birleşik Krallık', 'latitude': 55.86, 'longitude': -4.25},
      {'city_name': 'Guangzhou', 'country': 'Çin', 'latitude': 23.12, 'longitude': 113.26},
      {'city_name': 'Göreme', 'country': 'Türkiye', 'latitude': 38.64, 'longitude': 34.82},
    ],
    'h': [
      {'city_name': 'Hamburg', 'country': 'Almanya', 'latitude': 53.55, 'longitude': 9.99},
      {'city_name': 'Helsinki', 'country': 'Finlandiya', 'latitude': 60.16, 'longitude': 24.93},
      {'city_name': 'Hatay', 'country': 'Türkiye', 'latitude': 36.20, 'longitude': 36.16},
      {'city_name': 'Houston', 'country': 'Amerika Birleşik Devletleri', 'latitude': 29.76, 'longitude': -95.36},
      {'city_name': 'Hanoi', 'country': 'Vietnam', 'latitude': 21.02, 'longitude': 105.83},
    ],
    'i': [
      {'city_name': 'İstanbul', 'country': 'Türkiye', 'latitude': 41.00, 'longitude': 28.97},
      {'city_name': 'İzmir', 'country': 'Türkiye', 'latitude': 38.41, 'longitude': 27.12},
      {'city_name': 'Isparta', 'country': 'Türkiye', 'latitude': 37.76, 'longitude': 30.55},
      {'city_name': 'İskenderun', 'country': 'Türkiye', 'latitude': 36.58, 'longitude': 36.17},
      {'city_name': 'Incheon', 'country': 'Güney Kore', 'latitude': 37.45, 'longitude': 126.70},
    ],
    'j': [
      {'city_name': 'Cakarta', 'country': 'Endonezya', 'latitude': -6.20, 'longitude': 106.81},
      {'city_name': 'Johannesburg', 'country': 'Güney Afrika', 'latitude': -26.20, 'longitude': 28.04},
      {'city_name': 'Jaipur', 'country': 'Hindistan', 'latitude': 26.91, 'longitude': 75.78},
      {'city_name': 'Cenova', 'country': 'İtalya', 'latitude': 44.40, 'longitude': 8.94},
      {'city_name': 'Kraliyet Limanı', 'country': 'Jamaika', 'latitude': 17.93, 'longitude': -76.84},
    ],
    'k': [
      {'city_name': 'Kadıköy', 'country': 'Türkiye', 'latitude': 40.99, 'longitude': 29.02},
      {'city_name': 'Konya', 'country': 'Türkiye', 'latitude': 37.87, 'longitude': 32.48},
      {'city_name': 'Kayseri', 'country': 'Türkiye', 'latitude': 38.72, 'longitude': 35.48},
      {'city_name': 'Kars', 'country': 'Türkiye', 'latitude': 40.60, 'longitude': 43.09},
      {'city_name': 'Kiev', 'country': 'Ukrayna', 'latitude': 50.45, 'longitude': 30.52},
    ],
    'l': [
      {'city_name': 'Londra', 'country': 'Birleşik Krallık', 'latitude': 51.50, 'longitude': -0.12},
      {'city_name': 'Los Angeles', 'country': 'Amerika Birleşik Devletleri', 'latitude': 34.05, 'longitude': -118.24},
      {'city_name': 'Lizbon', 'country': 'Portekiz', 'latitude': 38.72, 'longitude': -9.13},
      {'city_name': 'Lyon', 'country': 'Fransa', 'latitude': 45.76, 'longitude': 4.83},
      {'city_name': 'Lima', 'country': 'Peru', 'latitude': -12.04, 'longitude': -77.04},
    ],
    'm': [
      {'city_name': 'Madrid', 'country': 'İspanya', 'latitude': 40.41, 'longitude': -3.70},
      {'city_name': 'Münih', 'country': 'Almanya', 'latitude': 48.13, 'longitude': 11.57},
      {'city_name': 'Moskova', 'country': 'Rusya', 'latitude': 55.75, 'longitude': 37.61},
      {'city_name': 'Melbourne', 'country': 'Avustralya', 'latitude': -37.81, 'longitude': 144.96},
      {'city_name': 'Manila', 'country': 'Filipinler', 'latitude': 14.59, 'longitude': 120.98},
    ],
    'n': [
      {'city_name': 'New York', 'country': 'Amerika Birleşik Devletleri', 'latitude': 40.71, 'longitude': -74.00},
      {'city_name': 'Nice', 'country': 'Fransa', 'latitude': 43.70, 'longitude': 7.26},
      {'city_name': 'Napoli', 'country': 'İtalya', 'latitude': 40.85, 'longitude': 14.26},
      {'city_name': 'Nairobi', 'country': 'Kenya', 'latitude': -1.29, 'longitude': 36.82},
      {'city_name': 'Yeni Delhi', 'country': 'Hindistan', 'latitude': 28.61, 'longitude': 77.20},
    ],
    'o': [
      {'city_name': 'Oslo', 'country': 'Norveç', 'latitude': 59.91, 'longitude': 10.75},
      {'city_name': 'Osaka', 'country': 'Japonya', 'latitude': 34.69, 'longitude': 135.50},
      {'city_name': 'Ödemiş', 'country': 'Türkiye', 'latitude': 38.23, 'longitude': 27.97},
      {'city_name': 'Orlando', 'country': 'Amerika Birleşik Devletleri', 'latitude': 28.53, 'longitude': -81.37},
      {'city_name': 'Oxford', 'country': 'Birleşik Krallık', 'latitude': 51.75, 'longitude': -1.25},
    ],
    'p': [
      {'city_name': 'Paris', 'country': 'Fransa', 'latitude': 48.85, 'longitude': 2.35},
      {'city_name': 'Pekin', 'country': 'Çin', 'latitude': 39.90, 'longitude': 116.40},
      {'city_name': 'Prag', 'country': 'Çekya', 'latitude': 50.07, 'longitude': 14.43},
      {'city_name': 'Portland', 'country': 'Amerika Birleşik Devletleri', 'latitude': 45.51, 'longitude': -122.67},
      {'city_name': 'Plymouth', 'country': 'Birleşik Krallık', 'latitude': 50.37, 'longitude': -4.14},
    ],
    'q': [
      {'city_name': 'Quebec', 'country': 'Kanada', 'latitude': 46.81, 'longitude': -71.20},
      {'city_name': 'Quito', 'country': 'Ekvador', 'latitude': -0.18, 'longitude': -78.46},
      {'city_name': 'Qingdao', 'country': 'Çin', 'latitude': 36.06, 'longitude': 120.38},
      {'city_name': 'Quanzhou', 'country': 'Çin', 'latitude': 24.87, 'longitude': 118.67},
      {'city_name': 'Kum', 'country': 'İran', 'latitude': 34.64, 'longitude': 50.87},
    ],
    'r': [
      {'city_name': 'Roma', 'country': 'İtalya', 'latitude': 41.90, 'longitude': 12.49},
      {'city_name': 'Rio de Janeiro', 'country': 'Brezilya', 'latitude': -22.90, 'longitude': -43.17},
      {'city_name': 'Riyad', 'country': 'Suudi Arabistan', 'latitude': 24.71, 'longitude': 46.67},
      {'city_name': 'Rotterdam', 'country': 'Hollanda', 'latitude': 51.92, 'longitude': 4.47},
      {'city_name': 'Riga', 'country': 'Letonya', 'latitude': 56.94, 'longitude': 24.10},
    ],
    's': [
      {'city_name': 'Şanlıurfa', 'country': 'Türkiye', 'latitude': 37.15, 'longitude': 38.79},
      {'city_name': 'Sivas', 'country': 'Türkiye', 'latitude': 39.75, 'longitude': 37.01},
      {'city_name': 'Samsun', 'country': 'Türkiye', 'latitude': 41.29, 'longitude': 36.33},
      {'city_name': 'Sidney', 'country': 'Avustralya', 'latitude': -33.86, 'longitude': 151.20},
      {'city_name': 'San Francisco', 'country': 'Amerika Birleşik Devletleri', 'latitude': 37.77, 'longitude': -122.41},
    ],
    't': [
      {'city_name': 'Trabzon', 'country': 'Türkiye', 'latitude': 41.00, 'longitude': 39.71},
      {'city_name': 'Tokyo', 'country': 'Japonya', 'latitude': 35.67, 'longitude': 139.65},
      {'city_name': 'Toronto', 'country': 'Kanada', 'latitude': 43.65, 'longitude': -79.38},
      {'city_name': 'Torino', 'country': 'İtalya', 'latitude': 45.07, 'longitude': 7.68},
      {'city_name': 'Tahran', 'country': 'İran', 'latitude': 35.68, 'longitude': 51.38},
    ],
    'u': [
      {'city_name': 'Üsküdar', 'country': 'Türkiye', 'latitude': 41.02, 'longitude': 29.01},
      {'city_name': 'Uşak', 'country': 'Türkiye', 'latitude': 38.68, 'longitude': 29.40},
      {'city_name': 'Utrecht', 'country': 'Hollanda', 'latitude': 52.09, 'longitude': 5.12},
      {'city_name': 'Ulan Batur', 'country': 'Moğolistan', 'latitude': 47.88, 'longitude': 106.90},
      {'city_name': 'Ufa', 'country': 'Rusya', 'latitude': 54.73, 'longitude': 55.97},
    ],
    'v': [
      {'city_name': 'Venedik', 'country': 'İtalya', 'latitude': 45.44, 'longitude': 12.31},
      {'city_name': 'Viyana', 'country': 'Avusturya', 'latitude': 48.20, 'longitude': 16.37},
      {'city_name': 'Vancouver', 'country': 'Kanada', 'latitude': 49.28, 'longitude': -123.12},
      {'city_name': 'Van', 'country': 'Türkiye', 'latitude': 38.50, 'longitude': 43.38},
      {'city_name': 'Valensiya', 'country': 'İspanya', 'latitude': 39.46, 'longitude': -0.37},
    ],
    'w': [
      {'city_name': 'Washington', 'country': 'Amerika Birleşik Devletleri', 'latitude': 38.90, 'longitude': -77.03},
      {'city_name': 'Varşova', 'country': 'Polonya', 'latitude': 52.22, 'longitude': 21.01},
      {'city_name': 'Wellington', 'country': 'Yeni Zelanda', 'latitude': -41.28, 'longitude': 174.77},
      {'city_name': 'Wuhan', 'country': 'Çin', 'latitude': 30.59, 'longitude': 114.30},
      {'city_name': 'Winnipeg', 'country': 'Kanada', 'latitude': 49.89, 'longitude': -97.13},
    ],
    'x': [
      {'city_name': 'Xiamen', 'country': 'Çin', 'latitude': 24.47, 'longitude': 118.08},
      {'city_name': 'Xi\'an', 'country': 'Çin', 'latitude': 34.26, 'longitude': 108.94},
      {'city_name': 'Xining', 'country': 'Çin', 'latitude': 36.61, 'longitude': 101.77},
      {'city_name': 'Xinyang', 'country': 'Çin', 'latitude': 32.12, 'longitude': 114.07},
      {'city_name': 'Xuchang', 'country': 'Çin', 'latitude': 34.01, 'longitude': 113.82},
    ],
    'y': [
      {'city_name': 'Yalova', 'country': 'Türkiye', 'latitude': 40.65, 'longitude': 29.27},
      {'city_name': 'Yozgat', 'country': 'Türkiye', 'latitude': 39.81, 'longitude': 34.80},
      {'city_name': 'Yokohama', 'country': 'Japonya', 'latitude': 35.44, 'longitude': 139.63},
      {'city_name': 'Yangon', 'country': 'Myanmar', 'latitude': 16.86, 'longitude': 96.19},
      {'city_name': 'Erivan', 'country': 'Ermenistan', 'latitude': 40.17, 'longitude': 44.51},
    ],
    'z': [
      {'city_name': 'Zonguldak', 'country': 'Türkiye', 'latitude': 41.45, 'longitude': 31.79},
      {'city_name': 'Zürih', 'country': 'İsviçre', 'latitude': 47.37, 'longitude': 8.54},
      {'city_name': 'Zagreb', 'country': 'Hırvatistan', 'latitude': 45.81, 'longitude': 15.97},
      {'city_name': 'Zaragoza', 'country': 'İspanya', 'latitude': 41.64, 'longitude': -0.88},
      {'city_name': 'Zhengzhou', 'country': 'Çin', 'latitude': 34.74, 'longitude': 113.62},
    ],
  };
}
