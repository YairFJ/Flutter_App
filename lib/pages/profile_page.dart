import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/favorite_recipes_screen.dart';
import '../screens/my_recipes_screen.dart';
import '../screens/account_settings_screen.dart';
import '../screens/help_support_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatelessWidget {
  final User user;
  final bool isEnglish;

  const ProfilePage({super.key, required this.user, this.isEnglish = false});

  Future<void> _createUserDocument() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
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

    if (!context.mounted) {
      return; // Agregar verificación después de operación async
    }

    final currentName = userDoc.data()?['name'] ?? '';
    nameController.text = currentName;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(isEnglish ? 'Change Username' : 'Cambiar Nombre de Usuario'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: isEnglish ? 'Name' : 'Nombre',
            hintText: isEnglish ? 'Enter your name' : 'Ingresa tu nombre',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
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
                        content: Text(isEnglish
                            ? 'Name updated successfully'
                            : 'Nombre actualizado con éxito'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEnglish
                            ? 'Error updating name'
                            : 'Error al actualizar el nombre'),
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

  Widget _buildProfileSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isTablet,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 2,
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 16,
            vertical: isTablet ? 16 : 8,
          ),
          leading: Icon(
            icon,
            color: const Color(0xFF96B4D8),
            size: isTablet ? 36 : 30,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Column(
      children: [
        _buildProfileSection(
          icon: Icons.person_outline,
          title: isEnglish ? 'Account Settings' : 'Configuración de Cuenta',
          subtitle: isEnglish ? 'Manage your account information' : 'Gestiona la información de tu cuenta',
          isTablet: isTablet,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AccountSettingsScreen(isEnglish: isEnglish),
              ),
            );
          },
        ),
        _buildProfileSection(
          icon: Icons.help_outline,
          title: isEnglish ? 'Help & Support' : 'Ayuda y Soporte',
          subtitle: isEnglish ? 'Get help and contact us' : 'Obtén ayuda y contacta con nosotros',
          isTablet: isTablet,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HelpSupportScreen(isEnglish: isEnglish),
              ),
            );
          },
        ),
        // NUEVA SECCIÓN DE POLÍTICA DE PRIVACIDAD
        _buildProfileSection(
          icon: Icons.privacy_tip_outlined,
          title: isEnglish ? 'Privacy Policy' : 'Política de Privacidad',
          subtitle: isEnglish
              ? 'Read our privacy policy'
              : 'Lee nuestra política de privacidad',
          isTablet: isTablet,
          onTap: () async {
            final url = isEnglish
                ? 'https://sites.google.com/view/gaugeyourrecipe-privacy-en/página-principal'
                : 'https://sites.google.com/view/gauge-your-recipe/página-principal';
            if (await canLaunch(url)) {
              await launch(url);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isEnglish
                      ? 'Could not open the link'
                      : 'No se pudo abrir el enlace'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final padding = size.width * 0.05;

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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

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
                  padding: EdgeInsets.symmetric(
                    vertical: size.height * 0.03,
                    horizontal: padding,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        SizedBox(height: size.height * 0.02),
                        CircleAvatar(
                          radius: isTablet ? 70 : 50,
                          backgroundColor: const Color(0xFFD6E3BB),
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: isTablet ? 56 : 40,
                              color: const Color(0xFF96B4D8),
                            ),
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: isTablet ? 24 : 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.email ?? 'Usuario',
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          isEnglish ? 'My Content' : 'Mi Contenido',
                          style: TextStyle(
                            fontSize: isTablet ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF96B4D8),
                          ),
                        ),
                      ),
                      _buildProfileSection(
                        icon: Icons.restaurant_menu,
                        title: isEnglish ? 'My Recipes' : 'Mis Recetas',
                        subtitle: isEnglish
                            ? 'Manage my creations'
                            : 'Gestionar mis creaciones',
                        isTablet: isTablet,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MyRecipesScreen(isEnglish: isEnglish),
                            ),
                          );
                        },
                      ),
                      _buildProfileSection(
                        icon: Icons.favorite,
                        title: isEnglish ? 'Favorite Recipes' : 'Recetas Favoritas',
                        subtitle: isEnglish
                            ? 'My collection'
                            : 'Mi colección',
                        isTablet: isTablet,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FavoriteRecipesScreen(isEnglish: isEnglish),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          isEnglish ? 'Settings' : 'Configuración',
                          style: TextStyle(
                            fontSize: isTablet ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF96B4D8),
                          ),
                        ),
                      ),
                      _buildSettingsSection(context),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
