class Schedule {
  final String id;
  final String mapelName;
  final String? teacherId;
  final String className;
  final String day;
  final String startTime;
  final String endTime;
  final String room;
  final String? kodeMtk;
  final int? sks;
  final String? kelPraktek;
  final String? kodeGabung;
  final DateTime createdAt;

  // Additional transient fields joined from 'profiles' if needed
  final String? teacherName;

  Schedule({
    required this.id,
    required this.mapelName,
    this.teacherId,
    required this.className,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
    this.kodeMtk,
    this.sks,
    this.kelPraktek,
    this.kodeGabung,
    required this.createdAt,
    this.teacherName,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      mapelName: json['mapel_name'],
      teacherId: json['teacher_id'],
      className: json['class_name'],
      day: json['day'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      room: json['room'],
      kodeMtk: json['kode_mtk'],
      sks: json['sks'],
      kelPraktek: json['kel_praktek'],
      kodeGabung: json['kode_gabung'],
      createdAt: DateTime.parse(json['created_at']),
      teacherName: json['profiles']?['full_name'], // joined field
    );
  }
}
