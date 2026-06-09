import 'package:flutter/material.dart';
import 'app_theme.dart';

class BuzzerControl extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onToggle;

  const BuzzerControl({
    super.key,
    required this.isActive,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isActive ? AppColors.bocorBg : AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.bocorBorder : AppColors.border,
          width: isActive ? 1 : 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              isActive ? '🔔' : '🔕',
              key: ValueKey(isActive),
              style: const TextStyle(fontSize: 26),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kontrol Buzzer',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isActive ? 'Aktif' : 'Nonaktif',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: isActive ? AppColors.bocor : AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: onToggle,
            activeColor: AppColors.bocor,
            activeTrackColor: AppColors.bocorBg,
            inactiveTrackColor: AppColors.border,
            inactiveThumbColor: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
