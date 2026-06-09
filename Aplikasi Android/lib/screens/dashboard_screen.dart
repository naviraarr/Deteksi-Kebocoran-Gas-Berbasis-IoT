import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/sensor_provider.dart';
import '../services/mqtt_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/status_card.dart';
import '../widgets/sensor_grid.dart';
import '../widgets/sensor_chart.dart';
import '../widgets/buzzer_control.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestSensorProvider);
    final history = ref.watch(sensorHistoryProvider);
    final connState = ref.watch(mqttConnectionProvider);
    final buzzerActive = ref.watch(buzzerActiveProvider);
    final controller = ref.read(sensorControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Ikon tabung gas kecil di sebelah judul
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: const Center(
                child: Text('🔥', style: TextStyle(fontSize: 16)),
              ),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pangkalan Gas Septi Handayani',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Monitoring LPG Real-time',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          _MqttStatusIndicator(
            state: connState,
            onReconnect: controller.reconnect,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.reconnect(),
        color: AppColors.accent,
        backgroundColor: AppColors.bgCard,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              StatusCard(data: latest),
              const SizedBox(height: 10),
              SensorGrid(data: latest),
              const SizedBox(height: 10),
              const SizedBox(height: 10),
              SensorChart(history: history),
              const SizedBox(height: 10),
              BuzzerControl(
                isActive: buzzerActive,
                onToggle: (val) => controller.toggleBuzzer(val),
              ),
              const SizedBox(height: 10),
              if (latest != null)
                Text(
                  'Update terakhir: ${_formatTime(latest.timestamp)}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _MqttStatusIndicator extends StatelessWidget {
  final MqttCurrentConnectionState state;
  final VoidCallback onReconnect;

  const _MqttStatusIndicator({required this.state, required this.onReconnect});

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    final String label;

    switch (state) {
      case MqttCurrentConnectionState.CONNECTED:
        dotColor = AppColors.normal;
        label = 'Online';
        break;
      case MqttCurrentConnectionState.CONNECTING:
        dotColor = AppColors.flameYellow;
        label = 'Connecting';
        break;
      default:
        dotColor = AppColors.bocor;
        label = 'Offline';
    }

    return GestureDetector(
      onTap: state == MqttCurrentConnectionState.DISCONNECTED ||
              state == MqttCurrentConnectionState.ERROR_WHEN_CONNECTING
          ? onReconnect
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: dotColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dotColor.withOpacity(0.35), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: state == MqttCurrentConnectionState.CONNECTED
                    ? [
                        BoxShadow(
                            color: dotColor.withOpacity(0.6), blurRadius: 6)
                      ]
                    : [],
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: dotColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
