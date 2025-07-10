import 'package:cloud_firestore/cloud_firestore.dart';

/// Limpia los campos innecesarios de los usuarios ya verificados en Firestore.
Future<void> limpiarCamposUsuariosVerificados() async {
  final firestore = FirebaseFirestore.instance;
  final usersRef = firestore.collection('users');

  // Obtiene todos los usuarios verificados
  final query = await usersRef.where('verified', isEqualTo: true).get();

  for (final doc in query.docs) {
    await usersRef.doc(doc.id).update({
      'verificationCode': FieldValue.delete(),
      'verificationCodeTimestamp': FieldValue.delete(),
      'lastVerificationAttempt': FieldValue.delete(),
      'needsVerification': FieldValue.delete(),
      'isEmailVerified': FieldValue.delete(), // Solo si decides usar solo 'verified'
    });
    print('Limpieza realizada para usuario:  [32m${doc.id} [0m');
  }

  print('Limpieza completada para todos los usuarios verificados.');
} 