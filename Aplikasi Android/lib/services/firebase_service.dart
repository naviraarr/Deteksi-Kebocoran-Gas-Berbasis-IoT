// lib/services/firebase_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';

// Result wrapper untuk pagination
class HistoryPage {
  final List<SensorData> data;
  final DocumentSnapshot? lastDoc; // cursor untuk halaman berikutnya

  const HistoryPage({required this.data, this.lastDoc});
}

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collectionReadings = 'sensor_readings';
  static const String _collectionDevices = 'devices';

  // ─────────────────────────────────────────────────────────────
  // SENSOR DATA
  // ─────────────────────────────────────────────────────────────

  /// Simpan satu pembacaan sensor ke Firestore
  static Future<void> saveSensorData(SensorData data) async {
    try {
      await _db.collection(_collectionReadings).add({
        'timestamp': Timestamp.fromDate(data.timestamp),
        'suhu': data.suhu,
        'humidity': data.humidity,
        'ppm': data.ppm,
        'adc': data.adc,
        'status': data.status, // int: 0=Normal, 1=Waspada, 2=Bocor
      });
    } catch (e) {
      debugPrint('[Firebase] Gagal simpan data: $e');
    }
  }

  /// Stream real-time N data terbaru (untuk halaman pertama)
  static Stream<List<SensorData>> streamHistory({int limit = 30}) {
    return _db
        .collection(_collectionReadings)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => _docToSensorData(doc)).toList());
  }

  /// Fetch halaman berikutnya (untuk infinite scroll)
  /// [startAfter] adalah cursor dari halaman sebelumnya
  static Future<HistoryPage> fetchHistoryPage({
    int limit = 30,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var query = _db
          .collection(_collectionReadings)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      // Kalau ada cursor, mulai setelah dokumen terakhir
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final data = snapshot.docs.map((doc) => _docToSensorData(doc)).toList();
      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      return HistoryPage(data: data, lastDoc: lastDoc);
    } catch (e) {
      debugPrint('[Firebase] Gagal fetch halaman: $e');
      return const HistoryPage(data: []);
    }
  }

  /// Ambil hanya event waspada & bocor dari Firestore
  static Future<List<SensorData>> fetchEvents({int limit = 50}) async {
    try {
      final snapshot = await _db
          .collection(_collectionReadings)
          .where('status', isGreaterThan: 0)
          .orderBy('status')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => _docToSensorData(doc)).toList();
    } catch (e) {
      debugPrint('[Firebase] Gagal fetch events: $e');
      return [];
    }
  }

  /// Hapus data lebih lama dari X hari (cleanup otomatis)
  static Future<void> deleteOldData({int olderThanDays = 30}) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: olderThanDays));
      final snapshot = await _db
          .collection(_collectionReadings)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoff))
          .get();

      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('[Firebase] Deleted ${snapshot.docs.length} old records');
    } catch (e) {
      debugPrint('[Firebase] Gagal hapus data lama: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FCM TOKEN
  // ─────────────────────────────────────────────────────────────

  /// Simpan FCM token device ke Firestore
  static Future<void> saveFcmToken(String token) async {
    try {
      await _db.collection(_collectionDevices).doc(token).set({
        'token': token,
        'platform': Platform.operatingSystem,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[Firebase] FCM token tersimpan');
    } catch (e) {
      debugPrint('[Firebase] Gagal simpan FCM token: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // HELPER
  // ─────────────────────────────────────────────────────────────

  static SensorData _docToSensorData(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SensorData(
      timestamp: (d['timestamp'] as Timestamp).toDate(),
      suhu: (d['suhu'] as num).toDouble(),
      humidity: (d['humidity'] as num).toDouble(),
      ppm: (d['ppm'] as num).toDouble(),
      adc: (d['adc'] as num).toInt(),
      status: (d['status'] as num).toInt(),
    );
  }
}