import 'dart:convert';

class Incident {
  final DateTime timestamp;
  final String event;
  final int objectId;
  final double confidence;
  final String? cameraId;

  Incident({
    required this.timestamp,
    required this.event,
    required this.objectId,
    required this.confidence,
    this.cameraId,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      timestamp: DateTime.parse(json['timestamp']),
      event: json['event'] ?? 'Unknown Event',
      objectId: json['object_id'] ?? 0,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      cameraId: json['camera_id'],
    );
  }

  // Helper to parse JSONL
  static List<Incident> parseJsonl(String responseBody) {
    return responseBody
        .split('\n')
        .where((line) => line.trim().isNotEmpty) // Ignore empty lines
        .map((line) => Incident.fromJson(jsonDecode(line)))
        .toList();
  }
}