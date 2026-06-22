class Teacher {
  final String id;
  final String profileId;
  final String? nip;
  final bool isWaliKelas;
  final String? waliClassId;
  final DateTime createdAt;

  // Joined fields
  final String? fullName;
  final String? email;
  final String? waliClassName;

  Teacher({
    required this.id,
    required this.profileId,
    this.nip,
    this.isWaliKelas = false,
    this.waliClassId,
    required this.createdAt,
    this.fullName,
    this.email,
    this.waliClassName,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'],
      profileId: json['profile_id'],
      nip: json['nip'],
      isWaliKelas: json['is_wali_kelas'] ?? false,
      waliClassId: json['wali_class_id'],
      createdAt: DateTime.parse(json['created_at']),
      fullName: json['profiles']?['full_name'],
      email: json['profiles']?['email'],
      waliClassName: json['classes']?['name'],
    );
  }
}
