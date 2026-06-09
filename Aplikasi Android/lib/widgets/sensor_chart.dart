import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/sensor_data.dart';
import 'app_theme.dart';

enum ChartMode { ppm, suhu, humidity }

class SensorChart extends StatefulWidget {
  final List<SensorData> history;

  const SensorChart({super.key, required this.history});

  @override
  State<SensorChart> createState() => _SensorChartState();
}

class _SensorChartState extends State<SensorChart> {
  ChartMode _mode = ChartMode.ppm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tren Sensor',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  _TabButton(
                    label: 'Gas',
                    active: _mode == ChartMode.ppm,
                    color: AppColors.accent,        // biru Elpiji
                    onTap: () => setState(() => _mode = ChartMode.ppm),
                  ),
                  const SizedBox(width: 4),
                  _TabButton(
                    label: 'Suhu',
                    active: _mode == ChartMode.suhu,
                    color: AppColors.flame,         // oranye api
                    onTap: () => setState(() => _mode = ChartMode.suhu),
                  ),
                  const SizedBox(width: 4),
                  _TabButton(
                    label: 'Humid',
                    active: _mode == ChartMode.humidity,
                    color: AppColors.steelBlue,     // biru baja tabung
                    onTap: () => setState(() => _mode = ChartMode.humidity),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: widget.history.isEmpty
                ? const Center(
                    child: Text(
                      'Menunggu data...',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  )
                : _buildChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final spots = _buildSpots();
    final color = _chartColor();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _horizontalInterval(),
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.border.withOpacity(0.8),
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, _) => Text(
                _formatAxisValue(value),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textMuted,
                  fontSize: 9,
                ),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withOpacity(0.3), color.withOpacity(0)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _buildSpots() {
    final data = widget.history;
    final recent = data.length > 60 ? data.sublist(data.length - 60) : data;
    return recent.asMap().entries.map((e) {
      final val = switch (_mode) {
        ChartMode.ppm => e.value.ppm,
        ChartMode.suhu => e.value.suhu,
        ChartMode.humidity => e.value.humidity,
      };
      return FlSpot(e.key.toDouble(), val);
    }).toList();
  }

  Color _chartColor() {
    return switch (_mode) {
      ChartMode.ppm => AppColors.accent,
      ChartMode.suhu => AppColors.flame,
      ChartMode.humidity => AppColors.steelBlue,
    };
  }

  double _horizontalInterval() {
    return switch (_mode) {
      ChartMode.ppm => 500,
      ChartMode.suhu => 10,
      ChartMode.humidity => 20,
    };
  }

  String _formatAxisValue(double value) {
    if (_mode == ChartMode.ppm && value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color.withOpacity(0.6) : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            color: active ? color : AppColors.textMuted,
            fontSize: 10,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}