import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Crear un proveedor de Google
      GoogleAuthProvider googleProvider = GoogleAuthProvider();

      // En Android, usa el flujo predeterminado
      if (Platform.isAndroid) {
        return await _auth.signInWithProvider(googleProvider);
      } 
      // En iOS, usa el flujo web
      else {
        return await _auth.signInWithPopup(googleProvider);
      }
    } catch (e) {
      print('Error en el inicio de sesión con Google: $e');
      return null;
    }
  }

  // Método para registrar usuario
  Future<UserCredential?> registerUser(String emailUser, String password, String nameUser) async {
    try {
      // Registro en Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailUser,
        password: password,
      );

      // Guardar en Firestore con los campos correctos
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'emailUser': emailUser,
          'nameUser': nameUser,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } catch (e) {
      print('Error en el registro: $e');
      rethrow;
    }
  }

  // Método para iniciar sesión
  Future<UserCredential?> loginUser(String emailUser, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailUser,
        password: password,
      );

      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } catch (e) {
      print('Error en el inicio de sesión: $e');
      rethrow;
    }
  }

  // Método para cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Método para actualizar datos del usuario
  Future<void> updateUserData(String uid, {String? emailUser, String? nameUser}) async {
    try {
      final Map<String, dynamic> updateData = {};
      if (emailUser != null) updateData['emailUser'] = emailUser;
      if (nameUser != null) updateData['nameUser'] = nameUser;
      
      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updateData);
      }
    } catch (e) {
      print('Error al actualizar datos del usuario: $e');
      rethrow;
    }
  }
} 