class Subject {
  final String id;
  final String code;
  final String name;
  final DateTime createdAt;

  Subject({
    required this.id,
    required this.code,
    required this.name,
    required this.createdAt,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
  };
}
