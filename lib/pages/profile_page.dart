import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/favorite_recipes_screen.dart';
import '../screens/my_recipes_screen.dart';

class ProfilePage extends StatelessWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: const Color(0xFF96B4D8),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF96B4D8),
              padding: const EdgeInsets.only(bottom: 24),
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFFD6E3BB),
                      child: Text(
                        user.email?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 40,
                          color: Color(0xFF96B4D8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.email ?? 'Usuario',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildProfileSection(
              icon: Icons.restaurant_menu,
              title: 'Mis Recetas',
              subtitle: 'Gestiona tus recetas creadas',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyRecipesScreen(),
                  ),
                );
              },
            ),
            _buildProfileSection(
              icon: Icons.favorite,
              title: 'Recetas Favoritas',
              subtitle: 'Recetas guardadas como favoritas',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FavoriteRecipesScreen(),
                  ),
                );
              },
            ),
            _buildProfileSection(
              icon: Icons.settings,
              title: 'Configuración',
              subtitle: 'Ajustes de la aplicación',
              onTap: () {
                // Navegar a configuración
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF96B4D8), size: 30),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}