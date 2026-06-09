// lib/services/mqtt_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

enum MqttCurrentConnectionState {
  IDLE,
  CONNECTING,
  CONNECTED,
  DISCONNECTED,
  ERROR_WHEN_CONNECTING
}

enum MqttSubscriptionState { IDLE, SUBSCRIBED }

class MQTTClientWrapper {
  MqttServerClient? client;

  MqttCurrentConnectionState connectionState = MqttCurrentConnectionState.IDLE;
  MqttSubscriptionState subscriptionState = MqttSubscriptionState.IDLE;

  static const String _broker =
      '6c28ed1cbf734262919a64bc8de07442.s1.eu.hivemq.cloud';
  static const String _username = 'skripsiotnap';
  static const String _password = 'Skripsi2026';
  static const String topicSensorData = 'lpg/sensor/data';
  static const String topicBuzzerControl = 'lpg/control/buzzer';

  // ── Callbacks untuk sensor_provider ──────────────────────────
  Function(MqttCurrentConnectionState)? onStateChanged;
  Function(Map<String, dynamic>)? onDataReceived;

  // ── Setup & Connect ───────────────────────────────────────────
  Future<void> prepareMqttClient() async {
    _setupMqttClient();
    await _connectClient();
    _subscribeToTopic(topicSensorData);
  }

  Future<void> _connectClient() async {
    try {
      print('[MQTT] Connecting...');
      connectionState = MqttCurrentConnectionState.CONNECTING;
      onStateChanged?.call(connectionState);
      await client!.connect(_username, _password);
    } on Exception catch (e) {
      print('[MQTT] Exception: $e');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      onStateChanged?.call(connectionState);
      client!.disconnect();
    }

    if (client!.connectionStatus!.state == MqttConnectionState.connected) {
      connectionState = MqttCurrentConnectionState.CONNECTED;
      onStateChanged?.call(connectionState);
      print('[MQTT] Connected!');
    } else {
      print('[MQTT] Failed - status: ${client!.connectionStatus}');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      onStateChanged?.call(connectionState);
      client!.disconnect();
    }
  }

  void _setupMqttClient() {
    client = MqttServerClient.withPort(_broker, 'skripsiotnap', 8883);
    client!.secure = true;
    client!.securityContext = SecurityContext.defaultContext;
    client!.keepAlivePeriod = 20;
    client!.onDisconnected = _onDisconnected;
    client!.onConnected = _onConnected;
    client!.onSubscribed = _onSubscribed;
  }

  // ── Subscribe & Listen ────────────────────────────────────────
  void _subscribeToTopic(String topicName) {
    print('[MQTT] Subscribing to $topicName');
    client!.subscribe(topicName, MqttQos.atMostOnce);

    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print('[MQTT] Message received: $payload');

      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        // Kirim data ke sensor_provider — semua logic (Firebase, state)
        // ditangani di sana
        onDataReceived?.call(data);
      } catch (e) {
        print('[MQTT] JSON error: $e');
      }
    });
  }

  // ── Publish ───────────────────────────────────────────────────
  void publishBuzzer(bool isOn) {
    if (client?.connectionStatus?.state != MqttConnectionState.connected) {
      print('[MQTT] Cannot publish — not connected');
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString(isOn ? 'ON' : 'OFF');
    client!.publishMessage(
        topicBuzzerControl, MqttQos.atLeastOnce, builder.payload!);
    print('[MQTT] Published: ${isOn ? "ON" : "OFF"}');
  }

  // ── Callbacks ─────────────────────────────────────────────────
  void _onConnected() {
    connectionState = MqttCurrentConnectionState.CONNECTED;
    onStateChanged?.call(connectionState);
    print('[MQTT] OnConnected callback');
  }

  void _onDisconnected() {
    connectionState = MqttCurrentConnectionState.DISCONNECTED;
    onStateChanged?.call(connectionState);
    print('[MQTT] OnDisconnected callback');
  }

  void _onSubscribed(String topic) {
    subscriptionState = MqttSubscriptionState.SUBSCRIBED;
    print('[MQTT] Subscribed to $topic');
  }

  // ── Disconnect ────────────────────────────────────────────────
  void disconnect() {
    try {
      client?.disconnect();
    } catch (_) {}
  }
}