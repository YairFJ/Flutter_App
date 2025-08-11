import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isGuestMode = false;

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      // Si no hay usuario, no estamos en modo invitado
      if (user == null) {
        _isGuestMode = false;
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isGuestMode => _isGuestMode;

  // Método para entrar en modo invitado
  void enterGuestMode() {
    _isGuestMode = true;
    notifyListeners();
  }

  // Método para salir del modo invitado
  void exitGuestMode() {
    _isGuestMode = false;
    notifyListeners();
  }

  // Método para verificar si el usuario puede realizar acciones que requieren autenticación
  bool canPerformAction() {
    return isAuthenticated && !_isGuestMode;
  }

  Future<void> register(String email, String password, String name) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.signInWithEmailAndPassword(email, password);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.signOut();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 