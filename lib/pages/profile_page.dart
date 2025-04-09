import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/favorite_recipes_screen.dart';
import '../screens/my_recipes_screen.dart';

class ProfilePage extends StatelessWidget {
  final User user;
  final bool isEnglish;

  const ProfilePage({super.key, required this.user, this.isEnglish = false});

  Future<void> _createUserDocument() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': user.displayName ?? 'Usuario',
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error creating user document: $e');
    }
  }

  Future<void> _updateUserName(BuildContext context) async {
    if (!context.mounted) return;
    
    final TextEditingController nameController = TextEditingController();
    
    // Obtener el nombre actual del usuario desde Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    if (!context.mounted) return;  // Agregar verificación después de operación async
    
    final currentName = userDoc.data()?['name'] ?? '';
    nameController.text = currentName;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnglish ? 'Change Username' : 'Cambiar Nombre de Usuario'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: isEnglish ? 'Name' : 'Nombre',
            hintText: isEnglish ? 'Enter your name' : 'Ingresa tu nombre',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isEnglish ? 'Cancel' : 'Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                try {
                  // Actualizar en Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({'name': newName});
                  
                  // Actualizar en Firebase Auth
                  await user.updateDisplayName(newName);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEnglish ? 'Name updated successfully' : 'Nombre actualizado con éxito'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEnglish ? 'Error updating name' : 'Error al actualizar el nombre'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(isEnglish ? 'Save' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEnglish ? 'My Profile' : 'Mi Perfil'),
        backgroundColor: const Color(0xFF96B4D8),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          print('Estado de la conexión: ${snapshot.connectionState}');
          print('Tiene datos: ${snapshot.hasData}');
          print('Existe el documento: ${snapshot.data?.exists}');
          print('ID del usuario: ${user.uid}');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Si el documento no existe, lo creamos
          if (!snapshot.hasData || !snapshot.data!.exists) {
            _createUserDocument();
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final userName = userData['name'] as String? ?? 'Usuario';
          
          return SingleChildScrollView(
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
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 40,
                              color: Color(0xFF96B4D8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.email ?? 'Usuario',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildProfileSection(
                  icon: Icons.restaurant_menu,
                  title: isEnglish ? 'My Recipes' : 'Mis Recetas',
                  subtitle: isEnglish ? 'Manage your created recipes' : 'Gestiona tus recetas creadas',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyRecipesScreen(isEnglish: isEnglish),
                      ),
                    );
                  },
                ),
                _buildProfileSection(
                  icon: Icons.favorite,
                  title: isEnglish ? 'Favorite Recipes' : 'Recetas Favoritas',
                  subtitle: isEnglish ? 'Recipes saved as favorites' : 'Recetas guardadas como favoritas',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FavoriteRecipesScreen(isEnglish: isEnglish),
                      ),
                    );
                  },
                ),
                _buildProfileSection(
                  icon: Icons.settings,
                  title: isEnglish ? 'Settings' : 'Configuración',
                  subtitle: isEnglish ? 'Change username' : 'Cambiar nombre de usuario',
                  onTap: () => _updateUserName(context),
                ),
              ],
            ),
          );
        },
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