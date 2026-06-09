# 🔥 Deteksi Kebocoran Gas LPG Berbasis IoT

Sistem deteksi kebocoran gas LPG secara real-time menggunakan ESP32, sensor MQ-6 & BME688, klasifikasi Random Forest, dan aplikasi monitoring berbasis Flutter dengan penyimpanan data ke Firebase Firestore.

---

## 📁 Struktur Repository

```
├── lpg_monitor/          # Aplikasi Flutter (Android)
├── arduino/              # Kode ESP32 (Arduino IDE)
│   └── SkenarioB_MQTT.ino
└── training/             # Training model Random Forest (Python/Colab)
    ├── dataset.csv
    └── training.ipynb
```

---

## 🧩 Komponen Sistem

| Komponen | Keterangan |
|---|---|
| ESP32 | Mikrokontroler utama |
| Sensor MQ-6 | Deteksi kadar gas LPG (ppm) |
| Sensor BME688 | Suhu & kelembapan |
| OLED SSD1306 | Tampilan lokal pada perangkat |
| HiveMQ Cloud | MQTT broker (TLS/SSL) |
| Flutter | Aplikasi monitoring Android |
| Firebase Firestore | Penyimpanan riwayat pembacaan |
| Random Forest | Model klasifikasi status gas |

---

## ⚙️ Cara Kerja

```
Sensor MQ-6 + BME688
        ↓
      ESP32
  (Random Forest)
        ↓ MQTT (TLS)
   HiveMQ Cloud
        ↓
  Flutter App ──→ Firebase Firestore
  (Dashboard)       (Riwayat data)
```

1. ESP32 membaca data suhu, kelembapan, dan kadar gas setiap 2 detik
2. Model Random Forest pada ESP32 mengklasifikasikan status: **Normal**, **Waspada**, atau **Bocor**
3. Data dikirim via MQTT ke HiveMQ Cloud
4. Aplikasi Flutter menerima data real-time dan menyimpannya ke Firestore
5. Riwayat pembacaan dapat diakses kapan saja melalui tab Riwayat

---

## 📱 Aplikasi Flutter

### Fitur
- Dashboard real-time (suhu, kelembapan, kadar gas LPG)
- Indikator status: Normal / Waspada / Bocor
- Riwayat pembacaan dengan infinite scroll dari Firestore
- Statistik sesi (jumlah Normal, Waspada, Bocor)
- Kontrol buzzer dari aplikasi

### Prerequisites
- Flutter SDK >= 3.0.0
- Dart >= 3.0.0
- Akun Firebase (Firestore aktif)

### Setup

1. Clone repository
```bash
git clone https://github.com/username/repo-name.git
cd repo-name/lpg_monitor
```

2. Install dependencies
```bash
flutter pub get
```

3. Setup Firebase
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

4. Jalankan aplikasi
```bash
flutter run
```

5. Build APK
```bash
flutter build apk --release
```

### Dependencies utama
```yaml
flutter_riverpod: state management
mqtt_client: koneksi MQTT ke HiveMQ
firebase_core: inisialisasi Firebase
cloud_firestore: penyimpanan & stream data
intl: format tanggal & waktu
```

---

## 🔌 Kode ESP32 (Arduino IDE)

### Hardware
| Pin ESP32 | Komponen |
|---|---|
| GPIO 35 | MQ-6 AOUT |
| GPIO 14 | Buzzer |
| GPIO 4, 5 | OLED SDA, SCL |
| GPIO 18, 19 | BME688 SDA, SCL |

### Library yang dibutuhkan
- `MQTT` by Joel Gaehwiler
- `ArduinoJson`
- `Adafruit BME680`
- `Adafruit SSD1306`
- `WiFiClientSecure` (built-in ESP32)
- `Eloquent ML` (untuk Random Forest inference)

### Setup
1. Buka `arduino/SkenarioB_MQTT.ino` di Arduino IDE
2. Sesuaikan konfigurasi WiFi:
```cpp
#define WIFI_SSID     "nama_wifi"
#define WIFI_PASSWORD "password_wifi"
```
3. Upload ke ESP32

### Format payload MQTT
```json
{
  "suhu": 28.5,
  "humidity": 65.2,
  "ppm": 120.3,
  "adc": 1024,
  "status": 0
}
```
`status`: `0` = Normal, `1` = Waspada, `2` = Bocor

---

## 🤖 Training Model (Python / Google Colab)

### Prerequisites
```
pandas
numpy
scikit-learn
micromlgen
```

### Cara menjalankan
1. Buka `training/training.ipynb` di Google Colab atau Jupyter
2. Upload `dataset.csv`
3. Jalankan semua cell
4. Output berupa file `random_forest_lpg.h` yang siap di-include ke kode Arduino

### Fitur input model
| Fitur | Keterangan |
|---|---|
| suhu | Suhu ruangan (°C) |
| humidity | Kelembapan relatif (%) |
| ppm | Kadar gas LPG (ppm) |
| adc | Nilai ADC raw sensor MQ-6 |

### Label output
| Label | Status |
|---|---|
| 0 | Normal |
| 1 | Waspada |
| 2 | Bocor |

---

## 🔧 Konfigurasi MQTT

| Parameter | Nilai |
|---|---|
| Broker | HiveMQ Cloud |
| Port | 8883 (TLS) |
| Topic data | `lpg/sensor/data` |
| Topic buzzer | `lpg/control/buzzer` |
| QoS | 1 |

---

## 📊 Firebase Firestore

Struktur koleksi `sensor_readings`:
```
{
  timestamp: Timestamp,
  suhu: number,
  humidity: number,
  ppm: number,
  adc: number,
  status: number (0/1/2)
}
```

---

## 👤 Author

**Navira Arditha Aulia** — 2209106010
*Universitas Mulawarman — 2026*

---

## 📄 Lisensi

Repository ini dibuat untuk keperluan skripsi. Dilarang menggunakan untuk keperluan komersial tanpa izin.