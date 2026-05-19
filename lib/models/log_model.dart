class LogModel {
  final String id;
  final String userId;
  final String userEmail;
  final String action;
  final String details;
  final DateTime timestamp;

  LogModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.action,
    required this.details,
    required this.timestamp,
  });

  factory LogModel.fromMap(Map<String, dynamic> map, String id) {
    return LogModel(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      action: map['action'] ?? '',
      details: map['details'] ?? '',
      timestamp: DateTime.parse(
          map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'action': action,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
