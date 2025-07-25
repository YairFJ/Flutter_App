import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/favorite_recipes_screen.dart';
import '../screens/user_recipes_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _updateUserName(BuildContext context, String currentName) async {
    final TextEditingController nameController = TextEditingController(text: currentName);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Actualizar Nombre'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ingresa tu nombre',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                try {
                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser != null) {
                    // Actualizar en Firestore
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .update({
                          'name': newName,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                    
                    // Actualizar en Firebase Auth
                    await currentUser.updateDisplayName(newName);

                    // Actualizar el nombre en todas las recetas del usuario
                    final recipesQuery = await FirebaseFirestore.instance
                        .collection('recipes')
                        .where('userId', isEqualTo: currentUser.uid)
                        .get();

                    final batch = FirebaseFirestore.instance.batch();
                    for (var doc in recipesQuery.docs) {
                      batch.update(doc.reference, {
                        'creatorName': newName,
                      });
                    }
                    await batch.commit();
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nombre actualizado con éxito'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al actualizar el nombre: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El nombre no puede estar vacío'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar el perfil'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final userName = userData?['name'] ?? 'Usuario';
          final userEmail = currentUser?.email ?? 'No disponible';

          return Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                userEmail,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.restaurant_menu),
                      title: const Text('Mis Recetas'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserRecipesScreen(),
                          ),
                        );
                      },
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.favorite),
                      title: const Text('Recetas Favoritas'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FavoriteRecipesScreen(),
                          ),
                        );
                      },
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: const Text('Cambiar Nombre de Usuario'),
                      onTap: () => _updateUserName(context, userName),
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),  
    );
  }
} 