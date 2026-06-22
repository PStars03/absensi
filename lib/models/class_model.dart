class ClassModel {
  final String id;
  final String name;
  final String level;
  final String academicYear;
  final DateTime createdAt;

  ClassModel({
    required this.id,
    required this.name,
    required this.level,
    required this.academicYear,
    required this.createdAt,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'],
      name: json['name'],
      level: json['level'],
      academicYear: json['academic_year'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'level': level,
    'academic_year': academicYear,
  };
}
