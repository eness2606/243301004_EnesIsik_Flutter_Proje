class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'admin' | 'student'
  final String studentNo;
  final String? roomId;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.studentNo,
    this.roomId,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      studentNo: map['studentNo'] ?? '',
      roomId: map['roomId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'studentNo': studentNo,
      'roomId': roomId,
    };
  }
}
