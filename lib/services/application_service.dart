import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/application_model.dart';
import 'log_service.dart';
import 'room_service.dart';

class ApplicationService {
  final _db = FirebaseFirestore.instance;
  final _log = LogService();
  final _roomService = RoomService();

  Stream<List<ApplicationModel>> getAllApplications() {
    return _db
        .collection('applications')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ApplicationModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<ApplicationModel>> getUserApplications(String userId) {
    return _db
        .collection('applications')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ApplicationModel.fromMap(d.data(), d.id)).toList());
  }

  Future<bool> hasActiveApplication(String userId, String roomId) async {
    final snap = await _db
        .collection('applications')
        .where('userId', isEqualTo: userId)
        .where('roomId', isEqualTo: roomId)
        .where('status', whereIn: ['pending', 'approved'])
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<void> createApplication({
    required String userId,
    required String userEmail,
    required ApplicationModel application,
  }) async {
    await _db.collection('applications').add(application.toMap());
    await _log.addLog(
      userId: userId,
      userEmail: userEmail,
      action: 'BASVURU_OLUSTURMA',
      details:
          '${application.roomNumber} numaralı odaya başvuru yapıldı.',
    );
  }

  Future<void> updateStatus({
    required String adminId,
    required String adminEmail,
    required String applicationId,
    required String userId,
    required String roomId,
    required String status,
    String? adminNote,
  }) async {
    final snap = await _db.collection('applications').doc(applicationId).get();
    final previousStatus = snap.data()?['status'] as String?;

    await _db.collection('applications').doc(applicationId).update({
      'status': status,
      'adminNote': adminNote,
    });

    if (status == 'approved' && previousStatus != 'approved') {
      await _roomService.incrementOccupancy(roomId);
      await _db.collection('users').doc(userId).update({'roomId': roomId});
    } else if (status == 'rejected' && previousStatus == 'approved') {
      await _roomService.decrementOccupancy(roomId);
      await _db.collection('users').doc(userId).update({'roomId': null});
    }

    await _log.addLog(
      userId: adminId,
      userEmail: adminEmail,
      action: 'BASVURU_GUNCELLEME',
      details: 'Başvuru ID: $applicationId → Durum: $status',
    );
  }
}
