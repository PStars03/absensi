import 'dart:typed_data';

class Student {
  final String id;
  final String profileId;
  final String? classId;
  final String? nis;
  final Uint8List? faceEmbedding;
  final DateTime createdAt;

  // Joined fields
  final String? className;
  final String? fullName;
  final String? email;

  Student({
    required this.id,
    required this.profileId,
    this.classId,
    this.nis,
    this.faceEmbedding,
    required this.createdAt,
    this.className,
    this.fullName,
    this.email,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      profileId: json['profile_id'],
      classId: json['class_id'],
      nis: json['nis'],
      faceEmbedding: json['face_embedding'] != null
          ? Uint8List.fromList(List<int>.from(json['face_embedding']))
          : null,
      createdAt: DateTime.parse(json['created_at']),
      className: json['classes']?['name'],
      fullName: json['profiles']?['full_name'],
      email: json['profiles']?['email'],
    );
  }

  bool get hasFaceEnrolled => faceEmbedding != null;
}
