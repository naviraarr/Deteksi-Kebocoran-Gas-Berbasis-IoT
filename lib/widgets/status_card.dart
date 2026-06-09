import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import 'app_theme.dart';

class StatusCard extends StatelessWidget {
  final SensorData? data;

  const StatusCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) return _buildLoading();

    final Color bg;
    final Color borderColor;
    final Color badgeColor;
    final Color badgeBg;
    final String label;
    final String icon;
    final String subtitle;
    final Color glowColor;

    switch (data!.status) {
      case 2:
        bg = AppColors.bocorBg;
        borderColor = AppColors.bocorBorder;
        badgeColor = AppColors.bocor;
        badgeBg = const Color(0xFF3A000D);
        label = 'GAS BOCOR!';
        icon = '🚨';
        subtitle = 'Segera Evakuasi dan Ventilasi Area';
        glowColor = AppColors.bocor;
        break;
      case 1:
        bg = AppColors.waspadaBg;
        borderColor = AppColors.waspadaBorder;
        badgeColor = AppColors.waspada;
        badgeBg = const Color(0xFF2E1400);
        label = 'WASPADA';
        icon = '🔥';
        subtitle = 'Kadar Gas Meningkat';
        glowColor = AppColors.flame;
        break;
      default:
        bg = AppColors.normalBg;
        borderColor = AppColors.normalBorder;
        badgeColor = AppColors.normal;
        badgeBg = const Color(0xFF012A1A);
        label = 'NORMAL';
        icon = '🍃';
        subtitle = 'Kondisi Aman';
        glowColor = AppColors.accent;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prediksi Sistem: ${data!.statusLabel}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeColor.withOpacity(0.5), width: 1),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: badgeColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Menunggu data dari ESP32...',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}