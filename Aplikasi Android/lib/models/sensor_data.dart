class SensorData {
  final double suhu;
  final double humidity;
  final double ppm;
  final int adc;
  final int status; // 0=Normal, 1=Waspada, 2=Bocor
  final DateTime timestamp;

  SensorData({
    required this.suhu,
    required this.humidity,
    required this.ppm,
    required this.adc,
    required this.status,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      suhu: (json['suhu'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      ppm: (json['ppm'] as num).toDouble(),
      adc: (json['adc'] as num).toInt(),
      status: (json['status'] as num).toInt(),
      timestamp: DateTime.now(),
    );
  }

  String get statusLabel {
    switch (status) {
      case 1:
        return 'Waspada';
      case 2:
        return 'Bocor';
      default:
        return 'Normal';
    }
  }

  bool get isNormal => status == 0;
  bool get isWaspada => status == 1;
  bool get isBocor => status == 2;
}
