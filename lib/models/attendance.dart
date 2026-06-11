class Attendance {
  final String id;
  final String scheduleId;
  final String userId;
  final String date;
  final String checkIn;
  final String? checkOut;
  final String status;
  final DateTime createdAt;

  // Additional transient fields
  final String? userName;

  Attendance({
    required this.id,
    required this.scheduleId,
    required this.userId,
    required this.date,
    required this.checkIn,
    this.checkOut,
    required this.status,
    required this.createdAt,
    this.userName,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      scheduleId: json['schedule_id'],
      userId: json['user_id'],
      date: json['date'],
      checkIn: json['check_in'],
      checkOut: json['check_out'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      userName: json['profiles']?['full_name'], // joined field
    );
  }
}
