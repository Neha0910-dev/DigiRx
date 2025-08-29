import 'dart:convert';

import 'package:http/http.dart' as http;

class FamilyMember {
  final String id;
  final String name;
  final String age;
  final String mobile;
  final String? blood;

  FamilyMember({
    required this.id,
    required this.name,
    required this.age,
    required this.mobile,
    this.blood,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? '',
      mobile: json['mobile'] ?? '',
      blood: json['blood'],
    );
  }
}

Future<List<FamilyMember>> fetchFamilyMembers(String customerId) async {
  final url = Uri.parse(
      'https://api1.thecuredesk.com/patient/family-members/$customerId');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data['success'] == true && data['familyMembers'] != null) {
      final List membersJson = data['familyMembers'];
      return membersJson.map((json) => FamilyMember.fromJson(json)).toList();
    } else {
      return [];
    }
  } else {
    throw Exception('Failed to fetch family members');
  }
}
