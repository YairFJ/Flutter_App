import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Reiniciar Firebase Auth
    await FirebaseAuth.instance.signOut();
  } catch (e) {
    debugPrint('Error inicializando Firebase: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) =>  LoginPage(),
        '/register': (context) =>  RegisterPage(),
      },
    );
  }
}

// Definir la clase PigeonUserDetail para manejar los detalles del usuario
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

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Comprobar si hay datos en el snapshot
        if (snapshot.hasData && snapshot.data != null) {
          // Convertir User de Firebase a PigeonUserDetail
          final PigeonUserDetail userData = PigeonUserDetail.fromUser(snapshot.data!);

          // Pasar userData a HomeScreen
          return HomeScreen(userData: userData);
        }

        return const LoginPage();
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  final PigeonUserDetail userData;

  const HomeScreen({super.key, required this.userData});

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            onPressed: signUserOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bienvenido',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Email: ${userData.email}',
              style: const TextStyle(fontSize: 16),
            ),
            if (userData.name != null)
              Text(
                'Nombre: ${userData.name}',
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}
