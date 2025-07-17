import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/favorite_recipes_screen.dart';
import '../screens/my_recipes_screen.dart';
import '../screens/account_settings_screen.dart';
import '../screens/help_support_screen.dart';
import 'login_page.dart'; // Import correcto para LoginPage
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
                      const SizedBox(height: 20), // Espacio opcional
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFFFF5252)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () async {
                                // Palabras aleatorias para confirmar
                                final palabrasES = [
                                  'taxi', 'hotel', 'radio', 'piano', 'mango', 'kiwi', 'motor', 'sofa', 'robot', 'virus',
                                  'gas', 'club', 'metro', 'foto', 'video', 'email', 'doctor', 'pizza', 'cafe'
                                ];
                                final palabrasEN = [
                                  'taxi', 'hotel', 'radio', 'piano', 'mango', 'kiwi', 'motor', 'sofa', 'robot', 'virus',
                                  'gas', 'club', 'metro', 'photo', 'video', 'email', 'doctor', 'pizza', 'coffee'
                                ];
                                final palabras = isEnglish ? palabrasEN : palabrasES;
                                palabras.shuffle();
                                final palabraClave = palabras.first;
                                final palabraController = TextEditingController();
                                bool palabraCorrecta = false;

                                final confirmPalabra = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      isEnglish ? 'Type the word to confirm' : 'Escribe la palabra para confirmar',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          isEnglish
                                            ? 'To delete your account, type the following word:'
                                            : 'Para eliminar tu cuenta, escribe la siguiente palabra:',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.red[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            palabraClave,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        TextField(
                                          controller: palabraController,
                                          textCapitalization: TextCapitalization.characters,
                                          decoration: InputDecoration(
                                            labelText: isEnglish ? 'Type the word' : 'Escribe la palabra',
                                            border: const OutlineInputBorder(),
                                            filled: true,
                                            fillColor: Colors.grey[100],
                                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                          ),
                                          style: const TextStyle(fontSize: 14),
                                          autofocus: true,
                                        ),
                                      ],
                                    ),
                                    actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text(isEnglish ? 'Cancel' : 'Cancelar', style: const TextStyle(fontSize: 14)),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          if (palabraController.text.trim().toLowerCase() == palabraClave) {
                                            palabraCorrecta = true;
                                            Navigator.pop(context, true);
                                          } else {
                                            palabraCorrecta = false;
                                            Navigator.pop(context, false);
                                          }
                                        },
                                        child: Text(isEnglish ? 'Continue' : 'Continuar', style: const TextStyle(fontSize: 14)),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmPalabra == true && palabraCorrecta) {
                                  // Confirmación final
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(isEnglish ? 'Delete Account?' : '¿Eliminar cuenta?'),
                                      content: Text(isEnglish
                                          ? 'This action will delete all your information and cannot be undone. Are you sure you want to continue?'
                                          : 'Esta acción eliminará toda tu información y no se puede deshacer. ¿Estás seguro de que deseas continuar?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text(isEnglish ? 'Cancel' : 'Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: Text(isEnglish ? 'Delete' : 'Eliminar'),
                                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      // Eliminar recetas del usuario
                                      final recipesQuery = await FirebaseFirestore.instance
                                          .collection('recipes')
                                          .where('userId', isEqualTo: user.uid)
                                          .get();
                                      final batch = FirebaseFirestore.instance.batch();
                                      for (var doc in recipesQuery.docs) {
                                        batch.delete(doc.reference);
                                      }
                                      // Eliminar documento del usuario
                                      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
                                      batch.delete(userDoc);
                                      await batch.commit();
                                      
                                      // Intentar eliminar cuenta de Auth
                                      try {
                                        await user.delete();
                                      } catch (authError) {
                                        // Si Firebase requiere re-autenticación, mostrar mensaje explicativo
                                        if (authError.toString().contains('requires-recent-login')) {
                                          if (context.mounted) {
                                            await showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text(isEnglish ? 'Authentication Required' : 'Autenticación Requerida'),
                                                content: Text(isEnglish
                                                    ? 'For security reasons, you need to log out and log back in before deleting your account. Your data has been removed from the database.'
                                                    : 'Por razones de seguridad, necesitas cerrar sesión y volver a entrar antes de eliminar tu cuenta. Tus datos han sido eliminados de la base de datos.'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      Navigator.of(context).pushAndRemoveUntil(
                                                        MaterialPageRoute(builder: (_) => const LoginPage()),
                                                        (route) => false,
                                                      );
                                                    },
                                                    child: Text(isEnglish ? 'OK' : 'Aceptar'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                          return;
                                        } else {
                                          rethrow;
                                        }
                                      }
                                      
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(isEnglish
                                                ? 'Account deleted successfully'
                                                : 'Cuenta eliminada con éxito'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        await Future.delayed(const Duration(milliseconds: 800));
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(builder: (_) => const LoginPage()),
                                          (route) => false,
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        String errorMessage = isEnglish
                                            ? 'Error deleting account: '
                                            : 'Error al eliminar la cuenta: ';
                                        errorMessage += e.toString();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(errorMessage),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                } else if (confirmPalabra == false && palabraController.text.isNotEmpty) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isEnglish
                                            ? 'The word does not match. Please try again.'
                                            : 'La palabra no coincide. Intenta de nuevo.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.delete_forever,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEnglish ? 'Delete Account' : 'Eliminar cuenta',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32), // O el valor que prefieras
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
