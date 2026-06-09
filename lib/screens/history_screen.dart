import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/sensor_data.dart';
import '../providers/sensor_provider.dart';
import '../services/firebase_service.dart';
import '../widgets/app_theme.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  static const int _pageSize = 30;

  StreamSubscription<List<SensorData>>? _streamSub;

  // Data dari stream (real-time, halaman pertama)
  List<SensorData> _liveData = [];
  bool _isConnected = false;

  // Data load more (pagination manual)
  List<SensorData> _olderData = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc; // cursor pagination Firestore

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _startStream();
    _scrollController.addListener(_onScroll);
  }

  // ── Stream real-time (30 data terbaru) ──────────────────────
  void _startStream() {
    _streamSub = FirebaseService.streamHistory(limit: _pageSize).listen(
      (data) {
        if (mounted) setState(() {
          _liveData = data;
          _isConnected = true;
        });
      },
      onError: (_) {
        if (mounted) setState(() => _isConnected = false);
      },
    );
  }

  // ── Scroll ke bawah → load more ──────────────────────────────
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  // ── Load halaman berikutnya dari Firestore ───────────────────
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    final result = await FirebaseService.fetchHistoryPage(
      limit: _pageSize,
      startAfter: _lastDoc,
    );

    setState(() {
      _olderData.addAll(result.data);
      _lastDoc = result.lastDoc;
      _hasMore = result.data.length == _pageSize;
      _isLoadingMore = false;
    });
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localHistory = ref.watch(sensorHistoryProvider);
    final events = ref.watch(eventLogProvider);

    // Gabung: live (stream) + older (pagination), deduplikasi by timestamp
    final liveTimestamps = _liveData.map((d) => d.timestamp).toSet();
    final deduped = [
      ..._liveData,
      ..._olderData.where((d) => !liveTimestamps.contains(d.timestamp)),
    ];
    final history = deduped.isNotEmpty ? deduped : localHistory;

    final normalCount  = history.where((d) => d.isNormal).length;
    final waspadaCount = history.where((d) => d.isWaspada).length;
    final bocorCount   = history.where((d) => d.isBocor).length;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Riwayat Kejadian',
                style: TextStyle(
                    fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
            Text('Log Deteksi Gas LPG',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _isConnected
                        ? AppColors.normal
                        : AppColors.textMuted,
                    shape: BoxShape.circle,
                    boxShadow: _isConnected
                        ? [BoxShadow(
                            color: AppColors.normal.withOpacity(0.6),
                            blurRadius: 6)]
                        : null,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _isConnected ? 'Live' : 'Offline',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isConnected
                        ? AppColors.normal
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatCard(
              normal: normalCount,
              waspada: waspadaCount,
              bocor: bocorCount,
              total: history.length,
            ),
            const SizedBox(height: 16),
            const Text('Kejadian Waspada & Bocor',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            events.isEmpty
                ? _EmptyState()
                : Column(
                    children:
                        events.map((d) => _EventLogItem(data: d)).toList()),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pembacaan Terakhir',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.accent.withOpacity(0.3)),
                  ),
                  child: Text('${history.length} data',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── List data ──────────────────────────────────────
            history.isEmpty
                ? _EmptyState()
                : Column(
                    children:
                        history.map((d) => _ReadingLogItem(data: d)).toList()),

            // ── Loading indicator di bawah ─────────────────────
            if (_isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),

            // ── Label tidak ada data lagi ──────────────────────
            if (!_hasMore && _olderData.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Semua data sudah ditampilkan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final int normal, waspada, bocor, total;
  const _StatCard(
      {required this.normal,
      required this.waspada,
      required this.bocor,
      required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Statistik Sesi ($total pembacaan)',
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
                child: _StatItem(
                    value: normal, label: 'Normal', color: AppColors.normal)),
            Expanded(
                child: _StatItem(
                    value: waspada,
                    label: 'Waspada',
                    color: AppColors.waspada)),
            Expanded(
                child: _StatItem(
                    value: bocor, label: 'Bocor', color: AppColors.bocor)),
          ]),
          if (total > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(children: [
                if (normal > 0)
                  Flexible(
                      flex: normal,
                      child: Container(height: 7, color: AppColors.normal)),
                if (waspada > 0)
                  Flexible(
                      flex: waspada,
                      child: Container(height: 7, color: AppColors.waspada)),
                if (bocor > 0)
                  Flexible(
                      flex: bocor,
                      child: Container(height: 7, color: AppColors.bocor)),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _StatItem(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('$value',
          style: TextStyle(
              fontFamily: 'Poppins',
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.textMuted,
              fontSize: 10)),
    ]);
  }
}

class _EventLogItem extends StatelessWidget {
  final SensorData data;
  const _EventLogItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final color  = data.isBocor ? AppColors.bocor : AppColors.waspada;
    final bg     = data.isBocor ? AppColors.bocorBg : AppColors.waspadaBg;
    final border = data.isBocor ? AppColors.bocorBorder : AppColors.waspadaBorder;

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        Container(
          width: 9, height: 9,
          decoration: BoxDecoration(
            color: color, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data.isBocor ? '🚨 GAS BOCOR' : '🔥 Waspada',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                Text(DateFormat('HH:mm:ss').format(data.timestamp),
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.textMuted,
                        fontSize: 10)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Suhu: ${data.suhu.toStringAsFixed(1)}°C  |  '
              'Humid: ${data.humidity.toStringAsFixed(1)}%  |  '
              'Gas: ${data.ppm >= 1000 ? data.ppm.toStringAsFixed(0) : data.ppm.toStringAsFixed(1)} ppm',
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textMuted,
                  fontSize: 10),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _ReadingLogItem extends StatelessWidget {
  final SensorData data;
  const _ReadingLogItem({required this.data});

  @override
  Widget build(BuildContext context) {
    final color = data.isBocor
        ? AppColors.bocor
        : data.isWaspada
            ? AppColors.waspada
            : AppColors.normal;

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(children: [
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            color: color, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(children: [
            Text(DateFormat('HH:mm:ss').format(data.timestamp),
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textMuted,
                    fontSize: 10)),
            const SizedBox(width: 8),
            Text(data.statusLabel,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
        Text(
          '${data.ppm >= 1000 ? data.ppm.toStringAsFixed(0) : data.ppm.toStringAsFixed(1)} ppm',
          style: const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.textSecondary,
              fontSize: 11),
        ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: const Center(
        child: Column(children: [
          Text('📭', style: TextStyle(fontSize: 30)),
          SizedBox(height: 8),
          Text('Belum ada data',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textMuted,
                  fontSize: 12)),
        ]),
      ),
    );
  }
}