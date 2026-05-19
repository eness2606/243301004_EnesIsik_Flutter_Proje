class ApplicationModel {
  final String id;
  final String userId;
  final String userName;
  final String studentNo;
  final String roomId;
  final String roomNumber;
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime date;
  final String? adminNote;

  ApplicationModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.studentNo,
    required this.roomId,
    required this.roomNumber,
    required this.status,
    required this.date,
    this.adminNote,
  });

  factory ApplicationModel.fromMap(Map<String, dynamic> map, String id) {
    return ApplicationModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      studentNo: map['studentNo'] ?? '',
      roomId: map['roomId'] ?? '',
      roomNumber: map['roomNumber'] ?? '',
      status: map['status'] ?? 'pending',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      adminNote: map['adminNote'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'studentNo': studentNo,
      'roomId': roomId,
      'roomNumber': roomNumber,
      'status': status,
      'date': date.toIso8601String(),
      'adminNote': adminNote,
    };
  }
}
