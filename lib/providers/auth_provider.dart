import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated, passwordRecovery }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.loading;
  User? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isPasswordRecovery => _status == AuthStatus.passwordRecovery;

  AuthProvider() {
    // Delay by one microtask to ensure Supabase is fully settled on web
    Future.microtask(_init);
  }

  Future<void> _init() async {
    try {
      _user = _authService.currentUser;
      _status = _user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      notifyListeners();

      _authService.authStateChanges.listen((event) {
        _user = event.session?.user;
        if (event.event == AuthChangeEvent.passwordRecovery) {
          _status = AuthStatus.passwordRecovery;
        } else {
          _status = _user != null
              ? AuthStatus.authenticated
              : AuthStatus.unauthenticated;
        }
        _errorMessage = null;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('[AuthProvider] init error: $e');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading();
    try {
      await _authService.signIn(email: email, password: password);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
  }) async {
    _setLoading();
    try {
      await _authService.signUp(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
      );
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  void _setLoading() {
    _errorMessage = null;
    notifyListeners();
  }
}
