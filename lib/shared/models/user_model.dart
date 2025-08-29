class User {
  final String id;
  final String name;

  final String phone;
  final DateTime? dateOfBirth;
  final String? profileImage;
  final String memberId;

  User(
      {required this.id,
      required this.name,
      required this.phone,
      this.dateOfBirth,
      this.profileImage,
      required this.memberId});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'profileImage': profileImage,
        "memberId": memberId
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      profileImage: json['profileImage'],
      memberId: json['memberId']);

  User copyWith({
    String? name,
    String? phone,
    DateTime? dateOfBirth,
    String? profileImage,
  }) =>
      User(
          id: id,
          name: name ?? this.name,
          phone: phone ?? this.phone,
          dateOfBirth: dateOfBirth ?? this.dateOfBirth,
          profileImage: profileImage ?? this.profileImage,
          memberId: memberId);
}
