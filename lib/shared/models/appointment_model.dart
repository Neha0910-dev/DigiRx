enum AppointmentStatus { upcoming, completed, cancelled }

class Appointment {
  final String id;
  final String doctorId;
  final String doctorName;
  final String patientId;
  final DateTime date;
  final String timeSlot;
  final double fee;
  final AppointmentStatus status;
  final String? notes;
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.patientId,
    required this.date,
    required this.timeSlot,
    required this.fee,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    // Map backend status to enum
    AppointmentStatus mappedStatus;
    switch (json['status']?.toString().toLowerCase()) {
      case 'pending':
      case 'waiting':
        mappedStatus = AppointmentStatus.upcoming;
        break;
      case 'completed':
        mappedStatus = AppointmentStatus.completed;
        break;
      case 'cancelled':
      case 'canceled': // just in case spelling differs
        mappedStatus = AppointmentStatus.cancelled;
        break;
      default:
        mappedStatus = AppointmentStatus.upcoming;
    }

    return Appointment(
      id: json['_id'] ?? '',
      doctorId: json['doctorId'] ?? '',
      doctorName: json['doctorName'] ?? '',
      patientId: json['customerId'] ?? '',
      date: DateTime.tryParse(json['appointmentTime'] ?? '') ?? DateTime.now(),
      timeSlot: json['timeSlot'] ?? '',
      fee: (json['fee'] ?? 0).toDouble(),
      status: mappedStatus,
      notes: json['notes'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'customerId': patientId,
      'appointmentTime': date.toIso8601String(),
      'timeSlot': timeSlot,
      'fee': fee,
      'status': status.toString().split('.').last,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
