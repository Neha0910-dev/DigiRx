import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surebook/shared/models/user_model.dart';
import 'dart:convert';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? token;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      try {
        final userMap = jsonDecode(userData);
        _currentUser = User.fromJson(userMap);
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading user data: $e');
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // Simulate API call delay
      await Future.delayed(const Duration(seconds: 1));

      // Simple validation - in real app, this would be server authentication
      if (email.isNotEmpty && password.length >= 6) {
        _setLoading(false);
        return true;
      } else {
        _setError('Invalid email or password');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Login failed. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  Future<Map<String, dynamic>?> sendSignupOtp({
    required String name,
    required String mobile,
    required String age,
    required String gender,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse("https://api1.thecuredesk.com/patient/send-signup-otp"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "mobile": mobile,
          "name": name,
          "age": age,
          "gender": gender,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["message"] != null) {
        return data;
      } else {
        _errorMessage = data["message"] ?? "Signup OTP failed";
        return null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> sendOtp(String mobile) async {
    _setLoading(true);

    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse("https://api1.thecuredesk.com/patient/send-login-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"mobile": mobile}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _setLoading(false);
        notifyListeners();
        return data;
      } else {
        _setError('Failed to send OTP');
        _setLoading(false);
      }
    } catch (e) {
      _setError('Something went wrong: $e');
    }

    _setLoading(false);
    notifyListeners();
  }

  Future<bool> verifySignupOtp({
    required String mobile,
    required String otp,
  }) async {
    _isLoading = true;
    notifyListeners();

    final url = 'https://api1.thecuredesk.com/patient/verify-signup-otp';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile, 'otp': otp}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = data['message'] ?? 'OTP verification failed';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOtp(String mobile, String otp) async {
    _setLoading(true);
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse("https://api1.thecuredesk.com/patient/verify-login-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"mobile": mobile, "otp": otp}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        token = data["token"];
        final userData =
            data["data"]; // 👈 this contains _id, name, mobile, etc.

        final user = User(
            id: userData["_id"],
            name: userData["name"] ?? "User",
            phone: userData["mobile"],
            memberId: userData["memberId"]);

        _currentUser = user;

        // 🔹 Save only user + token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token!);
        await prefs.setString("user_data", jsonEncode(user.toJson()));

        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(data["message"] ?? "Invalid OTP");
      }
    } catch (e) {
      _setError("Something went wrong: $e");
    }

    _setLoading(false);
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('token');

    _currentUser = null;
    notifyListeners();
  }

  Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  String _getNameFromEmail(String email) {
    final name = email.split('@').first;
    return name
        .split('.')
        .map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
