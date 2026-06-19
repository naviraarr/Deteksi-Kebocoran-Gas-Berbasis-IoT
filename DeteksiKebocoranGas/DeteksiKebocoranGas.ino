#include <Wire.h>
#include <math.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <MQTT.h>
#include <ArduinoJson.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BME680.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include "random_forest_lpg.h"

// ── WiFi ─────────────────────────────────────────────────────
#define WIFI_SSID     "nap"
#define WIFI_PASSWORD "inipunyanap"

// ── HiveMQ Cloud ─────────────────────────────────────────────
#define MQTT_BROKER   "6c28ed1cbf734262919a64bc8de07442.s1.eu.hivemq.cloud"
#define MQTT_PORT     8883
#define MQTT_CLIENT   "esp32-lpg-monitor"
#define MQTT_USER     "skripsiotnap"
#define MQTT_PASS     "Skripsi2026"

#define TOPIC_DATA    "lpg/sensor/data"
#define TOPIC_BUZZER  "lpg/control/buzzer"

// ── OLED ─────────────────────────────────────────────────────
#define SCREEN_WIDTH  128
#define SCREEN_HEIGHT 64
#define OLED_RESET    -1
#define OLED_ADDRESS  0x3C

TwoWire I2C_OLED = TwoWire(0);
TwoWire I2C_BME  = TwoWire(1);

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &I2C_OLED, OLED_RESET);

// ── PIN ──────────────────────────────────────────────────────
#define MQ6_AOUT_PIN  35
#define BUZZER_PIN    14

// ── KALIBRASI MQ-6 ───────────────────────────────────────────
#define RL_VALUE      10.0
#define RO_CLEAN_AIR  8.157
#define ADC_MAX       4095.0
#define VCC           3.3
#define MQ6_M         -0.47
#define MQ6_B          1.45

// ── LABEL KELAS ──────────────────────────────────────────────
#define KELAS_NORMAL   0
#define KELAS_WASPADA  1
#define KELAS_BOCOR    2

// ── OBJEK ────────────────────────────────────────────────────
Adafruit_BME680 bme(&I2C_BME);
Eloquent::ML::Port::RandomForest rf;

WiFiClientSecure wifiClient;
MQTTClient mqttClient(512);

// ── VARIABEL ─────────────────────────────────────────────────
float temperature   = 0;
float humidity      = 0;
float mq6_ppm       = 0;
int   adcRaw        = 0;
int   statusKelas   = KELAS_NORMAL;
bool  buzzerFromApp = false;

unsigned long lastPublish = 0;
const unsigned long PUBLISH_INTERVAL = 2000;

// ─────────────────────────────────────────────────────────────
// FUNGSI: Konversi ADC → PPM
// ─────────────────────────────────────────────────────────────
float convertToPPM(int adcValue) {
  float vout = adcValue * (VCC / ADC_MAX);
  if (vout <= 0.01) return 0.0;
  float rs    = RL_VALUE * ((VCC - vout) / vout);
  float ratio = rs / RO_CLEAN_AIR;
  float ppm   = pow(10, (log10(ratio) - MQ6_B) / MQ6_M);
  if (isnan(ppm) || isinf(ppm) || ppm < 0) return 0.0;
  return ppm;
}

// ─────────────────────────────────────────────────────────────
// FUNGSI: Baca semua sensor
// ─────────────────────────────────────────────────────────────
bool bacaSensor() {
  if (!bme.performReading()) {
    Serial.println("[ERROR] Gagal baca BME688!");
    return false;
  }
  temperature = bme.temperature;
  humidity    = bme.humidity;

  long adcSum = 0;
  for (int i = 0; i < 10; i++) {
    adcSum += analogRead(MQ6_AOUT_PIN);
    delay(10);
  }
  adcRaw  = adcSum / 10;
  mq6_ppm = convertToPPM(adcRaw);
  return true;
}

// ─────────────────────────────────────────────────────────────
// FUNGSI: Tampilkan di OLED
// ─────────────────────────────────────────────────────────────
void tampilkanOLED() {
  display.clearDisplay();

  display.fillRect(0, 0, 128, 14, WHITE);
  display.setTextColor(BLACK);
  display.setTextSize(1);
  display.setCursor(20, 3);
  display.print("DETEKSI GAS LPG");

  display.setTextColor(WHITE);
  display.setTextSize(1);

  display.setCursor(0, 17);
  display.print("Suhu :");
  display.setCursor(72, 17);
  display.printf("%.1f C", temperature);

  display.setCursor(0, 27);
  display.print("Humid:");
  display.setCursor(72, 27);
  display.printf("%.1f %%", humidity);

  display.setCursor(0, 37);
  display.print("Gas  :");
  display.setCursor(72, 37);
  if (mq6_ppm >= 1000)
    display.printf("%.0f ppm", mq6_ppm);
  else
    display.printf("%.1f ppm", mq6_ppm);

  display.drawLine(0, 50, 128, 50, WHITE);

  display.setTextSize(1);
  if (statusKelas == KELAS_BOCOR) {
    display.fillRect(0, 52, 128, 12, WHITE);
    display.setTextColor(BLACK);
    display.setCursor(22, 54);
    display.print("!! GAS BOCOR !!");
  } else if (statusKelas == KELAS_WASPADA) {
    display.drawRect(0, 52, 128, 12, WHITE);
    display.setTextColor(WHITE);
    display.setCursor(25, 54);
    display.print(">> WASPADA <<");
  } else {
    display.setTextColor(WHITE);
    display.setCursor(30, 54);
    display.print(">> NORMAL <<");
  }

  display.display();
}

// ─────────────────────────────────────────────────────────────
// FUNGSI: Buzzer
// ─────────────────────────────────────────────────────────────
void aktifkanAlarm(int kelas) {
  if (!buzzerFromApp) {
    digitalWrite(BUZZER_PIN, LOW);
    return;
  }
  if (kelas == KELAS_BOCOR) {
    for (int i = 0; i < 3; i++) {
      digitalWrite(BUZZER_PIN, HIGH); delay(200);
      digitalWrite(BUZZER_PIN, LOW);  delay(100);
    }
  } else if (kelas == KELAS_WASPADA) {
    digitalWrite(BUZZER_PIN, HIGH); delay(600);
    digitalWrite(BUZZER_PIN, LOW);
  } else {
    digitalWrite(BUZZER_PIN, LOW);
  }
}

// ─────────────────────────────────────────────────────────────
// MQTT: Callback subscribe
// ─────────────────────────────────────────────────────────────
void mqttCallback(String &topic, String &payload) {
  String msg = payload;
  msg.trim();

  if (topic == TOPIC_BUZZER) {
    if (msg == "ON") {
      buzzerFromApp = true;
      Serial.println("[MQTT] Buzzer → ON (dari Flutter)");
    } else if (msg == "OFF") {
      buzzerFromApp = false;
      digitalWrite(BUZZER_PIN, LOW);
      Serial.println("[MQTT] Buzzer → OFF (dari Flutter)");
    }
  }
}

// ─────────────────────────────────────────────────────────────
// MQTT: Publish data JSON
// ─────────────────────────────────────────────────────────────
void publishData() {
  if (!mqttClient.connected()) return;

  StaticJsonDocument<256> doc;
  doc["suhu"]     = round(temperature * 10.0) / 10.0;
  doc["humidity"] = round(humidity    * 10.0) / 10.0;
  doc["ppm"]      = round(mq6_ppm    * 10.0) / 10.0;
  doc["adc"]      = adcRaw;
  doc["status"]   = statusKelas;

  char buf[256];
  serializeJson(doc, buf);

  // QoS 1, retained = false
  bool ok = mqttClient.publish(TOPIC_DATA, buf, false, 1);
  Serial.printf("[MQTT] Publish → %s\n", ok ? "OK" : "GAGAL");
}

// ─────────────────────────────────────────────────────────────
// WiFi: Koneksi
// ─────────────────────────────────────────────────────────────
void connectWiFi() {
  Serial.printf("[WiFi] Menghubungkan ke %s", WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  int retries = 0;
  while (WiFi.status() != WL_CONNECTED && retries < 30) {
    delay(1000);
    Serial.print(".");
    retries++;
  }
  if (WiFi.status() == WL_CONNECTED)
    Serial.printf("\n[WiFi] Terhubung! IP: %s\n", WiFi.localIP().toString().c_str());
  else
    Serial.println("\n[WiFi] GAGAL — cek SSID/password.");
}

// ─────────────────────────────────────────────────────────────
// MQTT: Koneksi ke HiveMQ Cloud
// ─────────────────────────────────────────────────────────────
bool connectMQTT() {
  Serial.printf("[MQTT] Menghubungkan ke %s:%d ...\n", MQTT_BROKER, MQTT_PORT);

  mqttClient.begin(MQTT_BROKER, MQTT_PORT, wifiClient);
  mqttClient.onMessage(mqttCallback);
  mqttClient.setKeepAlive(60);

  bool ok = mqttClient.connect(MQTT_CLIENT, MQTT_USER, MQTT_PASS);

  if (ok) {
    Serial.println("[MQTT] Terhubung ke HiveMQ Cloud!");
    // Subscribe QoS 1
    mqttClient.subscribe(TOPIC_BUZZER, 1);
    Serial.printf("[MQTT] Subscribe → %s (QoS 1)\n", TOPIC_BUZZER);
  } else {
    Serial.printf("[MQTT] Gagal, lastError=%d\n", mqttClient.lastError());
  }
  return ok;
}

// ─────────────────────────────────────────────────────────────
// SETUP
// ─────────────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  Serial.println("\n=== Sistem Deteksi Gas LPG 3 Kelas + HiveMQ Cloud ===");

  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);
  analogReadResolution(12);

  I2C_OLED.begin(4, 5);
  I2C_BME.begin(18, 19);

  // Init OLED
  if (!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDRESS)) {
    Serial.println("[ERROR] OLED tidak ditemukan!");
    while (1) delay(1000);
  }
  display.clearDisplay();
  display.display();
  Serial.println("[OK] OLED siap.");

  // Init BME688
  if (!bme.begin(0x76)) {
    Serial.println("[ERROR] BME688 tidak ditemukan!");
    while (1) delay(1000);
  }
  bme.setTemperatureOversampling(BME680_OS_8X);
  bme.setHumidityOversampling(BME680_OS_2X);
  bme.setPressureOversampling(BME680_OS_4X);
  bme.setIIRFilterSize(BME680_FILTER_SIZE_3);
  bme.setGasHeater(320, 150);
  Serial.println("[OK] BME688 siap.");

  // Warming up MQ-6
  Serial.println("[INFO] Warming up MQ-6 (60 detik)...");
  for (int i = 60; i > 0; i--) {
    Serial.printf("  %d detik...\n", i);
    display.clearDisplay();
    display.setTextColor(WHITE);
    display.setTextSize(1);
    display.setCursor(10, 5);
    display.print("Warming up MQ-6...");
    display.setTextSize(2);
    display.setCursor(45, 25);
    display.printf("%ds", i);
    display.setTextSize(1);
    display.setCursor(5, 50);
    display.print("Mohon tunggu...");
    display.display();
    delay(1000);
  }
  Serial.println("[OK] Semua sensor siap!\n");

  // Koneksi WiFi
  connectWiFi();

  // TLS setInsecure
  wifiClient.setInsecure();

  // Init MQTT
  mqttClient.begin(MQTT_BROKER, MQTT_PORT, wifiClient);
  mqttClient.onMessage(mqttCallback);
  mqttClient.setKeepAlive(60);

  connectMQTT();

  Serial.println("Kelas: 0=Normal | 1=Waspada | 2=Bocor");
  Serial.println("────────────────────────────────────────────────");
}

// ─────────────────────────────────────────────────────────────
// LOOP
// ─────────────────────────────────────────────────────────────
void loop() {
  mqttClient.loop();

  if (!mqttClient.connected()) {
    Serial.println("[MQTT] Terputus, reconnect...");
    if (!connectMQTT()) {
      delay(5000);
      return;
    }
  }

  if (!bacaSensor()) {
    delay(2000);
    return;
  }

  float fitur[4] = { temperature, humidity, mq6_ppm, (float)adcRaw };
  statusKelas = rf.predict(fitur);

  Serial.printf("[%lus] Suhu:%.2f°C | Humid:%.2f%% | Gas:%.2f ppm | ADC:%d | Status:%d\n",
    millis() / 1000, temperature, humidity, mq6_ppm, adcRaw, statusKelas);

  tampilkanOLED();
  aktifkanAlarm(statusKelas);

  unsigned long now = millis();
  if (now - lastPublish >= PUBLISH_INTERVAL) {
    publishData();
    lastPublish = now;
  }
}