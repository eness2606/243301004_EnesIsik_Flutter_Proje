import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';
import 'log_service.dart';

class RoomService {
  final _db = FirebaseFirestore.instance;
  final _log = LogService();

  Stream<List<RoomModel>> getRooms() {
    return _db.collection('rooms').orderBy('number').snapshots().map(
          (snap) => snap.docs
              .map((d) => RoomModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Future<RoomModel?> getRoom(String roomId) async {
    final doc = await _db.collection('rooms').doc(roomId).get();
    if (!doc.exists) return null;
    return RoomModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> addRoom({
    required String userId,
    required String userEmail,
    required RoomModel room,
  }) async {
    await _db.collection('rooms').add(room.toMap());
    await _log.addLog(
      userId: userId,
      userEmail: userEmail,
      action: 'ODA_EKLEME',
      details: '${room.number} numaralı oda eklendi. Kapasite: ${room.capacity}',
    );
  }

  Future<void> updateRoom({
    required String userId,
    required String userEmail,
    required RoomModel room,
  }) async {
    await _db.collection('rooms').doc(room.id).update(room.toMap());
    await _log.addLog(
      userId: userId,
      userEmail: userEmail,
      action: 'ODA_GUNCELLEME',
      details: '${room.number} numaralı oda güncellendi.',
    );
  }

  Future<void> deleteRoom({
    required String userId,
    required String userEmail,
    required String roomId,
    required String roomNumber,
  }) async {
    await _db.collection('rooms').doc(roomId).delete();
    await _log.addLog(
      userId: userId,
      userEmail: userEmail,
      action: 'ODA_SILME',
      details: '$roomNumber numaralı oda silindi.',
    );
  }

  Future<void> incrementOccupancy(String roomId) async {
    await _db.collection('rooms').doc(roomId).update({
      'currentOccupancy': FieldValue.increment(1),
    });
  }

  Future<void> decrementOccupancy(String roomId) async {
    await _db.collection('rooms').doc(roomId).update({
      'currentOccupancy': FieldValue.increment(-1),
    });
  }
}
