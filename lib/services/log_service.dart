import 'package:cloud_firestore/cloud_firestore.dart';

class LogService {
  final _db = FirebaseFirestore.instance;

  Future<void> addLog({
    required String userId,
    required String userEmail,
    required String action,
    required String details,
  }) async {
    await _db.collection('logs').add({
      'userId': userId,
      'userEmail': userEmail,
      'action': action,
      'details': details,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
