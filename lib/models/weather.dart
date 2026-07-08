class DailyForecast {
  final String date;
  final int weatherCode;
  final double tempMax;
  final double tempMin;

  DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.tempMax,
    required this.tempMin,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      date: json['date'] ?? '',
      weatherCode: json['weather_code'] ?? 0,
      tempMax: (json['temp_max'] as num?)?.toDouble() ?? 0.0,
      tempMin: (json['temp_min'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'weather_code': weatherCode,
      'temp_max': tempMax,
      'temp_min': tempMin,
    };
  }
}

class WeatherData {
  final String cityName;
  final String country;
  final double latitude;
  final double longitude;
  final double temperature;
  final int relativeHumidity;
  final double apparentTemperature;
  final double precipitation;
  final int weatherCode;
  final String weatherDescription;
  final double windSpeed;
  final String time;
  final DateTime fetchedAt;
  final List<DailyForecast> dailyForecast;

  WeatherData({
    required this.cityName,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.relativeHumidity,
    required this.apparentTemperature,
    required this.precipitation,
    required this.weatherCode,
    required this.weatherDescription,
    required this.windSpeed,
    required this.time,
    required this.fetchedAt,
    required this.dailyForecast,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final dailyList = <DailyForecast>[];
    if (json['daily'] != null) {
      final dailyMap = json['daily'] as Map<String, dynamic>;
      final times = dailyMap['time'] as List<dynamic>?;
      final codes = dailyMap['weather_code'] as List<dynamic>?;
      final maxs = dailyMap['temperature_2m_max'] as List<dynamic>?;
      final mins = dailyMap['temperature_2m_min'] as List<dynamic>?;
      
      if (times != null && codes != null && maxs != null && mins != null) {
        for (int i = 0; i < times.length; i++) {
          dailyList.add(DailyForecast(
            date: times[i] as String,
            weatherCode: (codes[i] as num).toInt(),
            tempMax: (maxs[i] as num).toDouble(),
            tempMin: (mins[i] as num).toDouble(),
          ));
        }
      }
    } else if (json['daily_forecast'] != null) {
      final list = json['daily_forecast'] as List;
      dailyList.addAll(list.map((item) => DailyForecast.fromJson(item)));
    }

    return WeatherData(
      cityName: json['city_name'] ?? '',
      country: json['country'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      relativeHumidity: json['relative_humidity'] ?? 0,
      apparentTemperature: (json['apparent_temperature'] as num?)?.toDouble() ?? 0.0,
      precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0.0,
      weatherCode: json['weather_code'] ?? 0,
      weatherDescription: json['weather_description'] ?? '',
      windSpeed: (json['wind_speed'] as num?)?.toDouble() ?? 0.0,
      time: json['time'] ?? '',
      fetchedAt: json['fetched_at'] != null 
          ? DateTime.parse(json['fetched_at']) 
          : DateTime.now(),
      dailyForecast: dailyList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city_name': cityName,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'temperature': temperature,
      'relative_humidity': relativeHumidity,
      'apparent_temperature': apparentTemperature,
      'precipitation': precipitation,
      'weather_code': weatherCode,
      'weather_description': weatherDescription,
      'wind_speed': windSpeed,
      'time': time,
      'fetched_at': fetchedAt.toIso8601String(),
      'daily_forecast': dailyForecast.map((f) => f.toJson()).toList(),
    };
  }
}

class FavoriteCity {
  final String id;
  final String cityName;
  final String country;
  final double latitude;
  final double longitude;
  final double temperature;
  final DateTime addedAt;

  FavoriteCity({
    required this.id,
    required this.cityName,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.addedAt,
  });

  factory FavoriteCity.fromJson(Map<String, dynamic> json) {
    return FavoriteCity(
      id: json['id'] ?? '',
      cityName: json['city_name'] ?? '',
      country: json['country'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      addedAt: json['added_at'] != null 
          ? DateTime.parse(json['added_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'city_name': cityName,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'temperature': temperature,
      'added_at': addedAt.toIso8601String(),
    };
  }
}

class SearchHistory {
  final String id;
  final String cityName;
  final String country;
  final double temperature;
  final int weatherCode;
  final DateTime searchTime;

  SearchHistory({
    required this.id,
    required this.cityName,
    required this.country,
    required this.temperature,
    required this.weatherCode,
    required this.searchTime,
  });

  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    return SearchHistory(
      id: json['id'] ?? '',
      cityName: json['city_name'] ?? '',
      country: json['country'] ?? '',
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      weatherCode: json['weather_code'] ?? 0,
      searchTime: json['search_time'] != null 
          ? DateTime.parse(json['search_time']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'city_name': cityName,
      'country': country,
      'temperature': temperature,
      'weather_code': weatherCode,
      'search_time': searchTime.toIso8601String(),
    };
  }
}
