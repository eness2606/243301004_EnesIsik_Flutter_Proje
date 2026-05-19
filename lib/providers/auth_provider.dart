import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
    } else {
      _user = await _authService.getUserModel(firebaseUser.uid);
    }
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String studentNo,
    required String role,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.register(
        name: name,
        email: email,
        password: password,
        studentNo: studentNo,
        role: role,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapError(e.code);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.login(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapError(e.code);
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_user != null) {
      await _authService.logout(_user!.uid, _user!.email);
    }
    _user = null;
    notifyListeners();
  }

  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Şifre hatalı.';
      case 'email-already-in-use':
        return 'Bu e-posta zaten kullanımda.';
      case 'weak-password':
        return 'Şifre çok zayıf.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      default:
        return 'Bir hata oluştu: $code';
    }
  }
}
