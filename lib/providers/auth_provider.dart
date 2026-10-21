import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  bool _isLoading = false;
  bool _isGuestMode = false;
  bool _isFirestoreAdmin = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isGuestMode => _isGuestMode;
  bool get isAuthenticated => _user != null || _isGuestMode;
  String? get errorMessage => _errorMessage;

  // 100% Dynamic Admin Check via Cloud Firestore 'admins' Collection
  bool get isAdmin {
    if (_isGuestMode || _user == null || _user!.email == null) return false;
    return _isFirestoreAdmin;
  }

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
        _checkFirestoreAdminStatus(user);
      } else {
        _isFirestoreAdmin = false;
      }
      notifyListeners();
    });
  }

  Future<bool> verifyAdminStatusDirect(User user) async {
    if (user.email == null) {
      _isFirestoreAdmin = false;
      return false;
    }
    final cleanEmail = user.email!.trim().toLowerCase();

    try {
      final doc = await _db.collection('admins').doc(cleanEmail).get();
      if (doc.exists && doc.data()?['active'] == true) {
        _isFirestoreAdmin = true;
        notifyListeners();
        return true;
      }
    } catch (_) {}

    _isFirestoreAdmin = false;
    notifyListeners();
    return false;
  }

  void _checkFirestoreAdminStatus(User user) {
    if (user.email == null) return;
    final cleanEmail = user.email!.trim().toLowerCase();

    _db.collection('admins').doc(cleanEmail).snapshots().listen((doc) {
      if (doc.exists && doc.data()?['active'] == true) {
        _isFirestoreAdmin = true;
      } else {
        _isFirestoreAdmin = false;
      }
      notifyListeners();
    }, onError: (_) {
      _isFirestoreAdmin = false;
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
        if (_user != null) {
          await verifyAdminStatusDirect(_user!);
          _checkFirestoreAdminStatus(_user!);
        }
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
    _isFirestoreAdmin = false;
    _user = null;
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
