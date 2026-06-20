# Deteksi Kebocoran Gas LPG Berbasis IoT

Sistem deteksi kebocoran gas LPG real-time menggunakan ESP32, sensor MQ-6 & BME688, klasifikasi Random Forest, dan aplikasi Android berbasis Flutter.

## Navira Arditha Aulia (2209106010)
### Universitas Mulawarman 2026

---

## Komponen

| Komponen | Fungsi |
|---|---|
| ESP32 | Mikrokontroler utama |
| MQ-6 | Deteksi kadar gas LPG (ppm) |
| BME688 | Suhu & kelembapan |
| HiveMQ Cloud | MQTT broker (TLS/SSL) |
| Flutter | Aplikasi monitoring Android |
| Firebase Firestore | Penyimpanan riwayat data |

---

## Cara Kerja

```
ESP32 (MQ-6 + BME688)
  → Random Forest → MQTT → Flutter App → Firestore
```

1. ESP32 membaca sensor setiap 2 detik
2. Model Random Forest mengklasifikasikan: **Normal / Waspada / Bocor**
3. Data dikirim via MQTT ke HiveMQ Cloud
4. Aplikasi Flutter menampilkan data real-time dan menyimpan ke Firestore

---

## Setup ESP32

1. Buka `arduino/DeteksiKebocoranGas.ino` di Arduino IDE
2. Sesuaikan kredensial WiFi:
```cpp
#define WIFI_SSID     "nama_wifi"
#define WIFI_PASSWORD "password_wifi"
```
3. Upload ke ESP32

**Pin:**

| GPIO | Komponen |
|---|---|
| 35 | MQ-6 AOUT |
| 14 | Buzzer |
| 4, 5 | OLED SDA/SCL |
| 18, 19 | BME688 SDA/SCL |

---

## Setup Aplikasi Flutter

```bash
flutter pub get
flutterfire configure
flutter run
```

---

## Training Model

1. Buka `training/training.ipynb` di Google Colab
2. Upload `dataset.csv` dan jalankan semua cell
3. Output: `random_forest_lpg.h` → copy ke folder Arduino

---

*Dilarang digunakan untuk keperluan komersial tanpa izin.*
