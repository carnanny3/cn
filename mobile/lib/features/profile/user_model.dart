class UserProfile {
  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
  });

  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['fullName'] as String,
        phoneNumber: json['phoneNumber'] as String?,
      );
}
