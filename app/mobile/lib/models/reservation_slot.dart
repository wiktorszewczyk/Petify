class ReservationSlot {
  final int id;
  final int petId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String? reservedBy;

  ReservationSlot({
    required this.id,
    required this.petId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.reservedBy,
  });

  factory ReservationSlot.fromJson(Map<String, dynamic> json) {
    try {
      return ReservationSlot(
        id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
        petId: json['petId'] is int ? json['petId'] : int.parse(json['petId'].toString()),
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        status: json['status'] ?? 'UNKNOWN',
        reservedBy: json['reservedBy'],
      );
    } catch (e) {
      print('Error parsing ReservationSlot from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status,
      'reservedBy': reservedBy,
    };
  }
}