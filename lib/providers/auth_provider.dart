import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  bool _isGuestMode = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isGuestMode => _isGuestMode;
  bool get isAuthenticated => _user != null || _isGuestMode;
  String? get errorMessage => _errorMessage;

  String get displayName {
    if (_isGuestMode) return 'গেস্ট ইউজার';
    return _user?.displayName ?? _user?.email?.split('@').first ?? 'যাত্রী';
  }

  String get email {
    if (_isGuestMode) return 'guest@brtc.com';
    return _user?.email ?? 'অজানা ইমেইল';
  }

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (user != null) {
        _isGuestMode = false;
      }
      notifyListeners();
    });
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final credential = await _authService.signInWithGoogle();
      if (credential != null) {
        _user = credential.user;
        _isGuestMode = false;
        _setLoading(false);
        return true;
      } else {
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'গুগল সাইন-ইন করতে সমস্যা হয়েছে: $e';
      _setLoading(false);
      return false;
    }
  }

  void continueAsGuest() {
    _isGuestMode = true;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
    _isGuestMode = false;
    _user = null;
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
