import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surebook/shared/models/appointment_model.dart';
import 'dart:convert';

class AppointmentProvider extends ChangeNotifier {
  List<Appointment> _appointments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Appointment> getAppointmentsByStatus(AppointmentStatus status) {
    return _appointments
        .where((appointment) => appointment.status == status)
        .toList();
  }

  Future<void> loadAppointments(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      final url = Uri.parse(
          'https://api1.thecuredesk.com/patient/appointments/$userId');
      final response = await http.get(
        url,
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        _appointments = data.map((json) => Appointment.fromJson(json)).toList();

        // Sort appointments by date
        _appointments.sort((a, b) => b.date.compareTo(a.date));

        // Optional: save to SharedPreferences for offline use
        final appointmentsData = _appointments
            .map((appointment) => jsonEncode(appointment.toJson()))
            .toList();
        await prefs.setStringList('appointments_$userId', appointmentsData);
      } else {
        _errorMessage = 'Failed to load appointments';
        debugPrint('Error: ${response.body}');
      }
    } catch (e) {
      _errorMessage = 'Failed to load appointments';
      debugPrint('Error loading appointments: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> bookAppointment({
    required String doctorId,
    required String doctorName,
    required String patientId,
    required DateTime date,
    required String timeSlot,
    required double fee,
    String? notes,
  }) async {
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      // Check if the time slot is already booked
      final existingAppointment = _appointments.any((appointment) =>
          appointment.doctorId == doctorId &&
          appointment.date.year == date.year &&
          appointment.date.month == date.month &&
          appointment.date.day == date.day &&
          appointment.timeSlot == timeSlot &&
          appointment.status == AppointmentStatus.upcoming);

      if (existingAppointment) {
        _errorMessage = 'This time slot is already booked';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final appointment = Appointment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        doctorId: doctorId,
        doctorName: doctorName,
        patientId: patientId,
        date: date,
        timeSlot: timeSlot,
        fee: fee,
        status: AppointmentStatus.upcoming,
        notes: notes,
        createdAt: DateTime.now(),
      );

      _appointments.insert(0, appointment);
      await _saveAppointments(patientId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to book appointment';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Future<void> cancelAppointment(String appointmentId) async {
  //   try {
  //     final index = _appointments.indexWhere((apt) => apt.id == appointmentId);
  //     if (index != -1) {
  //       _appointments[index] = _appointments[index].copyWith(
  //         status: AppointmentStatus.cancelled,
  //       );
  //       // Save to storage - get userId from the appointment
  //       final userId = _appointments[index].patientId;
  //       await _saveAppointments(userId);
  //       notifyListeners();
  //     }
  //   } catch (e) {
  //     _errorMessage = 'Failed to cancel appointment';
  //     notifyListeners();
  //   }
  // }

  List<Appointment> getUpcomingAppointments() {
    final now = DateTime.now();
    return _appointments
        .where((appointment) =>
            appointment.date.isAfter(now) &&
            appointment.status == AppointmentStatus.upcoming)
        .toList();
  }

  List<Appointment> getAppointmentHistory() {
    return _appointments
        .where((appointment) =>
            appointment.status == AppointmentStatus.completed ||
            appointment.status == AppointmentStatus.cancelled)
        .toList();
  }

  List<String> getBookedSlotsForDate(String doctorId, DateTime date) {
    return _appointments
        .where((appointment) =>
            appointment.doctorId == doctorId &&
            appointment.date.year == date.year &&
            appointment.date.month == date.month &&
            appointment.date.day == date.day &&
            appointment.status == AppointmentStatus.upcoming)
        .map((appointment) => appointment.timeSlot)
        .toList();
  }

  Future<void> _saveAppointments(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appointmentsData = _appointments
          .map((appointment) => jsonEncode(appointment.toJson()))
          .toList();
      await prefs.setStringList('appointments_$userId', appointmentsData);
    } catch (e) {
      debugPrint('Error saving appointments: $e');
    }
  }

  void _clearError() {
    _errorMessage = null;
  }

  double getTotalSpent() {
    return _appointments
        .where(
            (appointment) => appointment.status == AppointmentStatus.completed)
        .fold(0.0, (sum, appointment) => sum + appointment.fee);
  }

  int getTotalAppointments() {
    return _appointments
        .where(
            (appointment) => appointment.status != AppointmentStatus.cancelled)
        .length;
  }
}
