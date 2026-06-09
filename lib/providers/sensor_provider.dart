// lib/providers/sensor_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sensor_data.dart';
import '../services/mqtt_service.dart';
import '../services/firebase_service.dart'; // ← tambah

// ── MQTT Client (singleton per scope) ────────────────────────
final mqttServiceProvider = Provider<MQTTClientWrapper>((ref) {
  final service = MQTTClientWrapper();
  ref.onDispose(() => service.disconnect());
  return service;
});

// ── Providers ─────────────────────────────────────────────────
final mqttConnectionProvider = StateProvider<MqttCurrentConnectionState>(
    (ref) => MqttCurrentConnectionState.IDLE);

final latestSensorProvider = StateProvider<SensorData?>((ref) => null);
final sensorHistoryProvider = StateProvider<List<SensorData>>((ref) => []);
final eventLogProvider = StateProvider<List<SensorData>>((ref) => []);
final buzzerActiveProvider = StateProvider<bool>((ref) => false);

final sensorControllerProvider = Provider<SensorController>((ref) {
  final ctrl = SensorController(ref);
  ref.onDispose(() => ctrl.dispose());
  return ctrl;
});

class SensorController {
  final Ref _ref;
  Timer? _reconnectTimer;

  SensorController(this._ref) {
    Future.microtask(() => _init());
  }

  Future<void> _init() async {
    final mqtt = _ref.read(mqttServiceProvider);

    mqtt.onStateChanged = (MqttCurrentConnectionState state) {
      _ref.read(mqttConnectionProvider.notifier).state = state;
    };

    mqtt.onDataReceived = (Map<String, dynamic> json) {
      try {
        final data = SensorData.fromJson(json);

        // Update state lokal
        _ref.read(latestSensorProvider.notifier).state = data;
        _addToHistory(data);

        // ← Simpan ke Firebase (fire-and-forget, tidak block UI)
        FirebaseService.saveSensorData(data);
      } catch (_) {}
    };

    await mqtt.prepareMqttClient();
  }

  void _addToHistory(SensorData data) {
    // Riwayat semua pembacaan (maks 200 lokal)
    final history = List<SensorData>.from(_ref.read(sensorHistoryProvider));
    history.add(data);
    if (history.length > 200) history.removeAt(0);
    _ref.read(sensorHistoryProvider.notifier).state = history;

    // Event log khusus waspada & bocor (maks 100)
    if (!data.isNormal) {
      final events = List<SensorData>.from(_ref.read(eventLogProvider));
      events.insert(0, data);
      if (events.length > 100) events.removeLast();
      _ref.read(eventLogProvider.notifier).state = events;
    }
  }

  void toggleBuzzer(bool isOn) {
    _ref.read(mqttServiceProvider).publishBuzzer(isOn);
    _ref.read(buzzerActiveProvider.notifier).state = isOn;
  }

  Future<void> reconnect() async {
    final mqtt = _ref.read(mqttServiceProvider);
    mqtt.disconnect();
    await Future.delayed(const Duration(seconds: 1));
    await mqtt.prepareMqttClient();
  }

  void dispose() {
    _reconnectTimer?.cancel();
  }
}