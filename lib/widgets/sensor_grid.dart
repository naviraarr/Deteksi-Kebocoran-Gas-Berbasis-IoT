import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import 'app_theme.dart';

class SensorGrid extends StatelessWidget {
  final SensorData? data;

  const SensorGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SensorCard(
            icon: '🌡️',
            value: data != null ? data!.suhu.toStringAsFixed(1) : '--',
            unit: '°C',
            label: 'Suhu',
            accentColor: const Color(0xFF2196F3), // biru utama
            bgColor: const Color(0xFF001A2E), // biru gelap background
            borderColor: const Color(0xFF0D47A1), // biru border
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SensorCard(
            icon: '💧',
            value: data != null ? data!.humidity.toStringAsFixed(1) : '--',
            unit: '%',
            label: 'Kelembapan',
            accentColor: const Color(0xFF4CAF50), // hijau utama
            bgColor: const Color(0xFF001A00), // hijau gelap background
            borderColor: const Color(0xFF1B5E20), // hijau border
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SensorCard(
            icon: '💨',
            value: data != null ? _formatPpm(data!.ppm) : '--',
            unit: 'ppm',
            label: 'Gas LPG',
            accentColor: data != null ? _ppmColor(data!.ppm) : AppColors.accent,
            bgColor: data != null ? _ppmBg(data!.ppm) : const Color(0xFF051525),
            borderColor: data != null
                ? _ppmColor(data!.ppm).withOpacity(0.35)
                : AppColors.border,
          ),
        ),
      ],
    );
  }

  String _formatPpm(double ppm) {
    if (ppm >= 1000) return ppm.toStringAsFixed(0);
    return ppm.toStringAsFixed(1);
  }

  Color _ppmColor(double ppm) {
    if (ppm >= 1000) return const Color(0xFFD32F2F); // merah bahaya
    if (ppm >= 500) return const Color(0xFFFF5722); // merah oranye waspada
    return const Color(0xFF4CAF50); // hijau normal
  }

  Color _ppmBg(double ppm) {
    if (ppm >= 1000) return const Color(0xFF1A0000);
    if (ppm >= 500) return const Color(0xFF1A0800);
    return const Color(0xFF001A00);
  }
}

class _SensorCard extends StatelessWidget {
  final String icon;
  final String value;
  final String unit;
  final String label;
  final Color accentColor;
  final Color bgColor;
  final Color borderColor;

  const _SensorCard({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.accentColor,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: accentColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
