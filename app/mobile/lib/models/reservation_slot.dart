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
    return ReservationSlot(
      id: json['id'],
      petId: json['petId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: json['status'],
      reservedBy: json['reservedBy'],
    );
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