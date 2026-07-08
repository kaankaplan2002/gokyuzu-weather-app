# GökYüzü - Premium Flutter Hava Durumu Uygulaması

GökYüzü; tamamen istemci tarafında (pure Flutter) çalışan, herhangi bir harici backend API veya yerel veritabanı sunucusu kurulumu gerektirmeyen, modern ve responsive bir arayüz tasarımına sahip premium bir hava durumu uygulamasıdır.

## 🌟 Özellikler
- **Doğrudan API Entegrasyonu**: Open-Meteo API'leri (Geocoding ve Forecast) doğrudan uygulama içinden çağrılır. Herhangi bir API anahtarı (key) gerektirmez.
- **Konum Arama**: Girilen şehir isimlerini enlem ve boylam koordinatlarına otomatik olarak dönüştürür.
- **Detaylı Ölçümler**: Sıcaklık, Hissedilen Sıcaklık (Thermostat), Nem Oranı, Rüzgar Hızı ve Yağış Miktarı gibi kritik hava durumu verilerini sunar.
- **Yerel Veri Depolama**: Kullanıcının favori şehirleri ve arama geçmişi, `shared_preferences` paketi aracılığıyla cihaz üzerinde JSON formatında kalıcı olarak saklanır.
- **Responsive Düzen**: Büyük ekranlarda (Web, Tablet) yan yana panelli yerleşim, mobil dikey ekranlarda ise dikey kaydırılabilir düzen sunar.
- **Aura Efektleri**: Bulunan konunun güncel hava durumu koduna (açık, yağmurlu, karlı, fırtınalı vb.) bağlı olarak değişen dinamik kart arka planı ve gölge aydınlatmaları.

---

## 📂 Proje Yapısı

```
WEATHER APP/
├── README.md               # Proje dökümantasyonu (Bu dosya)
├── .gitignore              # Git yoksayma dosyası (Flutter standart)
├── pubspec.yaml            # Flutter proje ayarları ve paket tanımları (http, intl, shared_preferences)
│
└── lib/
    ├── main.dart           # Uygulama giriş noktası ve global M3 koyu tema
    │
    ├── models/
    │   └── weather.dart    # Veri Modelleri (WeatherData, FavoriteCity, SearchHistory)
    │
    ├── services/
    │   ├── api_service.dart # Open-Meteo doğrudan API çağrıları
    │   └── storage_service.dart # SharedPreferences ile yerel veritabanı yönetimi
    │
    └── screens/
        └── dashboard_screen.dart # Glassmorphic kontrol paneli (Arama, detaylar, favoriler, geçmiş)
```

---

## 🚀 Kurulum ve Çalıştırma

Uygulamayı yerel geliştirme ortamınızda çalıştırmak için aşağıdaki adımları takip edin.

### Önkoşullar
- Bilgisayarınızda **Flutter SDK** (versiyon 3.0.0 veya üzeri) kurulu olmalıdır.
- İnternet bağlantısı (Şehir arama ve hava durumunu çekebilmek için).

### Çalıştırma Adımları

1. Bağımlılıkları yükleyin:
   ```bash
   flutter pub get
   ```

2. Uygulamayı Chrome üzerinde çalıştırın (veya bağlı bir emülatör/cihaz seçin):
   ```bash
   flutter run -d chrome
   ```

3. Mobil testler için emülatör açıkken çalıştırın:
   ```bash
   flutter run
   ```

---

## 📦 Üretime Dağıtım (Production Build)

Uygulamanızı farklı platformlar için derlemek için aşağıdaki standart Flutter komutlarını kullanabilirsiniz:

- **Web Derlemesi**:
  ```bash
  flutter build web --release
  ```
  Çıktı klasörü: `build/web/`

- **Android (APK) Derlemesi**:
  ```bash
  flutter build apk --release
  ```
  Çıktı klasörü: `build/app/outputs/flutter-apk/`

- **iOS Derlemesi**:
  ```bash
  flutter build ios --release
  ```

---

## 🛠️ Kullanılan Harici Servisler

- **Open-Meteo Geocoding API**: Coğrafi isim aramaları için.
  - `https://geocoding-api.open-meteo.com/v1/search`
- **Open-Meteo Forecast API**: Hava durumu verileri için.
  - `https://api.open-meteo.com/v1/forecast`
- **Google Fonts (Outfit)**: Premium tipografi.
