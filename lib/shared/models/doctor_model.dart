class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String profileImage;
  final double rating;
  final int experienceYears;
  final double consultationFee;
  final String location;
  final List<String> availableDays;
  final List<String> availableTimeSlots;
  final String education;
  final String hospital;
  final String mobile;
  final String email;
  final List<Branch> branches;
  final Client? client;
  Doctor(
      {required this.id,
      required this.name,
      required this.specialty,
      required this.profileImage,
      this.rating = 0.0,
      this.experienceYears = 0,
      this.consultationFee = 0.0,
      this.location = '',
      this.availableDays = const [],
      this.availableTimeSlots = const [],
      this.education = '',
      this.hospital = '',
      this.email = '',
      this.branches = const [],
      this.client,
      this.mobile = ''});

  factory Doctor.fromApi(Map<String, dynamic> json) {
    return Doctor(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? 'General',
      profileImage: json['profileImage'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      experienceYears: (json['experienceYears'] ?? 0),
      consultationFee: (json['consultationFee'] ?? 0).toDouble(),
      location: json['branchId'] != null && json['branchId'].isNotEmpty
          ? json['branchId'][0]['branch'] ?? ''
          : '',
      availableDays: [],
      availableTimeSlots: [],
      education: '',
      mobile: json['mobile'] ?? '',
      branches: json['branchId'] != null
          ? (json['branchId'] as List).map((b) => Branch.fromApi(b)).toList()
          : [],
      email: json['email'] ?? '',
      hospital: json['clientId'] != null ? json['clientId']['name'] ?? '' : '',
      client:
          json['clientId'] != null ? Client.fromApi(json['clientId']) : null,
    );
  }
}

class Branch {
  final String id;
  final String name;

  Branch({required this.id, required this.name});

  factory Branch.fromApi(Map<String, dynamic> json) {
    return Branch(
      id: json['_id'] ?? '',
      name: json['branch'] ?? '',
    );
  }
}

class Client {
  final String id;
  final String name;

  Client({required this.id, required this.name});

  factory Client.fromApi(Map<String, dynamic> json) {
    return Client(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
