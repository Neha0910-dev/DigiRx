import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:surebook/shared/models/doctor_model.dart';

class DoctorProvider extends ChangeNotifier {
  List<Doctor> _doctors = [];
  List<Doctor> _filteredDoctors = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedSpecialty = 'All Specialties';
  String _sortOption = 'Highest Rated';
  double _minRating = 0.0;
  bool _hasMore = true;
  int _page = 1;
  final int _limit = 10;
  int _totalPages = 1;
  List<Doctor> get doctors => _filteredDoctors;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedSpecialty => _selectedSpecialty;
  String get sortOption => _sortOption;
  double get minRating => _minRating;
  bool get hasMore => _page <= _totalPages;

  Future<void> loadDoctors({bool refresh = false, String? search}) async {
    if (_isLoading || (!refresh && !hasMore)) return;

    if (refresh) {
      _page = 1;
      _doctors.clear();
      _totalPages = 1; // reset total pages for new search
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Update search query
      if (search != null) _searchQuery = search;

      final queryParams = {
        'page': '$_page',
        'limit': '$_limit',
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
      };

      final uri = Uri.parse("https://api1.thecuredesk.com/patient/doctors")
          .replace(queryParameters: queryParams);

      print("➡️ Calling: $uri");

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);

        final List<dynamic> data = decoded['data'] ?? [];
        final newDoctors = data.map((json) => Doctor.fromApi(json)).toList();

        if (refresh) {
          _doctors = newDoctors;
        } else {
          _doctors.addAll(newDoctors);
        }

        _totalPages = decoded['totalPages'] ?? 1;
        _page++; // move to next page

        _applyFiltersAndSort(); // apply search/sort filters on the combined list
      } else {
        print('❌ Failed to load doctors: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching doctors: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void resetSearch() {
    _searchQuery = '';
    _page = 1;
    _doctors.clear();
    _totalPages = 1;
    _applyFiltersAndSort();
    notifyListeners();
  }

  Future<bool> bookAppointment({
    required String memberId,
    required String customerId,
    required DateTime appointmentTime,
    required String branchId,
    required String clientId,
    required String doctorId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final url = "https://api1.thecuredesk.com/patient/book-appointment";

      final body = {
        "memberId": memberId,
        "customerId": customerId,
        "appoinmentTime": appointmentTime.toUtc().toIso8601String(),
        "branchId": branchId,
        "clientId": clientId,
        "doctorId": doctorId,
      };

      print("➡️ Booking Appointment: $body");

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print("✅ Appointment booked successfully: ${data['message']}");
        return true;
      } else {
        print("❌ Failed to book: ${data['message'] ?? response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Error booking appointment: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // void searchDoctors(String query) {
  //   _searchQuery = query;
  //   _applyFiltersAndSort();
  //   notifyListeners();
  // }

  void searchDoctors(String value) {
    loadDoctors(refresh: true, search: value);
    // notifyListeners();
  }

  void filterBySpecialty(String specialty) {
    _selectedSpecialty = specialty;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void filterByRating(double rating) {
    _minRating = rating;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void sortDoctors(String sortOption) {
    _sortOption = sortOption;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void _applyFiltersAndSort() {
    _filteredDoctors = _doctors.where((doctor) {
      final matchesSearch = _searchQuery.isEmpty ||
          doctor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doctor.specialty.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doctor.location.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesSpecialty = _selectedSpecialty == 'All Specialties' ||
          doctor.specialty == _selectedSpecialty;

      final matchesRating = doctor.rating >= _minRating;

      return matchesSearch && matchesSpecialty && matchesRating;
    }).toList();

    // Apply sorting
    switch (_sortOption) {
      case 'Highest Rated':
        _filteredDoctors.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Most Experienced':
        _filteredDoctors
            .sort((a, b) => b.experienceYears.compareTo(a.experienceYears));
        break;
      case 'Lowest Fee':
        _filteredDoctors
            .sort((a, b) => a.consultationFee.compareTo(b.consultationFee));
        break;
      case 'Earliest Available':
        _filteredDoctors.shuffle();
        break;
    }
  }

  Doctor? getDoctorById(String id) {
    try {
      return _doctors.firstWhere((doctor) => doctor.id == id);
    } catch (e) {
      return null;
    }
  }
}
