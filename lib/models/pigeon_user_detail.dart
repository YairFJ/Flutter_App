import 'package:firebase_auth/firebase_auth.dart';

class PigeonUserDetail {
  final String? email;
  final String? name;

  PigeonUserDetail({required this.email, required this.name});

  factory PigeonUserDetail.fromUser(User user) {
    return PigeonUserDetail(
      email: user.email,
      name: user.displayName,
    );
  }
} 