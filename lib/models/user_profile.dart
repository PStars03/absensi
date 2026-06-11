class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? identityNumber;
  final String? className;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.identityNumber,
    this.className,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      role: json['role'],
      identityNumber: json['identity_number'],
      className: json['class_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'identity_number': identityNumber,
      'class_name': className,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
