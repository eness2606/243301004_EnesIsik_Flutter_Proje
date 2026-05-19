import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'log_service.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _log = LogService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    required String studentNo,
    required String role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = UserModel(
      uid: cred.user!.uid,
      name: name,
      email: email,
      role: role,
      studentNo: studentNo,
    );
    await _db.collection('users').doc(user.uid).set(user.toMap());
    await _log.addLog(
      userId: user.uid,
      userEmail: email,
      action: 'KAYIT',
      details: '$name sisteme kayıt oldu. Rol: $role',
    );
    return user;
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = await getUserModel(cred.user!.uid);
    await _log.addLog(
      userId: cred.user!.uid,
      userEmail: email,
      action: 'GİRİŞ',
      details: '${user?.name} sisteme giriş yaptı.',
    );
    return user;
  }

  Future<void> logout(String userId, String userEmail) async {
    await _log.addLog(
      userId: userId,
      userEmail: userEmail,
      action: 'ÇIKIŞ',
      details: 'Kullanıcı sistemden çıkış yaptı.',
    );
    await _auth.signOut();
  }
}
