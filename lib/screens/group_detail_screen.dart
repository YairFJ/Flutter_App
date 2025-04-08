import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/group.dart';
import '../models/recipe.dart';
import 'group_recipe_detail_screen.dart';
import 'group_recipe_form_screen.dart';
import 'group_admin_screen.dart';

class GroupDetailScreen extends StatelessWidget {
  final Group group;
  final bool isEnglish;
  
  const GroupDetailScreen({
    super.key, 
    required this.group,
    this.isEnglish = false,
  });

  @override
  Widget build(BuildContext context) {
    final String currentUser = FirebaseAuth.instance.currentUser!.uid;
    bool isMember = group.members.contains(currentUser);
    bool isCreator = group.creatorId == currentUser;

    Future<void> requestJoin() async {
      try {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(group.id)
            .update({
          'pendingMembers': FieldValue.arrayUnion([currentUser])
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Solicitud enviada. Espera la aprobación del administrador.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al enviar la solicitud: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    Future<void> joinGroup() async {
      try {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(group.id)
            .update({
          'members': FieldValue.arrayUnion([currentUser])
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Te has unido a la comunidad'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al unirse a la comunidad: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    Future<void> leaveGroup() async {
      final currentUser = FirebaseAuth.instance.currentUser!.uid;

      // Verificar si el usuario es el creador del grupo
      if (group.creatorId == currentUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No puedes salir de un grupo que has creado.'),
            backgroundColor: Colors.red,
          ),
        );
        return; // Salir de la función si es el creador
      }

      try {
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(group.id)
            .update({
          'members': FieldValue.arrayRemove([currentUser])
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Has salido del grupo.'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pop(context);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al salir del grupo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          group.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(isEnglish ? 'Community Information' : 'Información de la Comunidad'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(isEnglish ? 'Name' : 'Nombre'),
                          subtitle: Text(group.name),
                          leading: const Icon(Icons.group),
                        ),
                        ListTile(
                          title: Text(isEnglish ? 'Description' : 'Descripción'),
                          subtitle: Text(group.description),
                          leading: const Icon(Icons.description),
                        ),
                        ListTile(
                          title: Text(isEnglish ? 'Created by' : 'Creado por'),
                          subtitle: Text(group.creatorId),
                          leading: const Icon(Icons.person),
                        ),
                        ListTile(
                          title: Text(isEnglish ? 'Members' : 'Miembros'),
                          subtitle: Text('${group.members.length}'),
                          leading: const Icon(Icons.people),
                        ),
                        ListTile(
                          title: Text(isEnglish ? 'Private' : 'Privado'),
                          subtitle: Text(group.isPrivate ? (isEnglish ? 'Yes' : 'Sí') : (isEnglish ? 'No' : 'No')),
                          leading: const Icon(Icons.lock),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(isEnglish ? 'Close' : 'Cerrar'),
                    ),
                  ],
                ),
              );
            },
          ),
          if (isCreator)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupAdminScreen(group: group),
                  ),
                );
              },
            ),
          if (isMember && !isCreator)
            IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.red),
              onPressed: leaveGroup,
              tooltip: 'Salir del Grupo',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnglish ? 'Description' : 'Descripción',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  group.description,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEnglish ? 'Community Recipes' : 'Recetas de la Comunidad',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isMember && !group.isPendingMember(currentUser))
            ElevatedButton(
              onPressed: group.isPrivate ? requestJoin : joinGroup,
              child: Text(
                group.isPrivate
                    ? 'Solicitar Unirme al Grupo'
                    : 'Unirme al Grupo',
              ),
            )
          else if (group.isPendingMember(currentUser))
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Solicitud pendiente de aprobación',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Expanded(
            child: isMember
                ? StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('groups')
                        .doc(group.id)
                        .collection('recipes')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final recipes = snapshot.data!.docs
                          .map((doc) => Recipe.fromDocument(doc))
                          .toList();

                      if (recipes.isEmpty) {
                        return const Center(
                            child: Text('No hay recetas en este grupo.'));
                      }

                      return ListView.builder(
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return ListTile(
                            title: Text(recipe.title),
                            subtitle: Text(recipe.description ?? ''),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GroupRecipeDetailScreen(
                                  recipe: recipe,
                                  group: group,
                                  isEnglish: isEnglish,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  )
                : const Center(
                    child: Text('Únete al grupo para ver las recetas.'),
                  ),
          ),
        ],
      ),
      floatingActionButton: isMember
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupRecipeFormScreen(group: group),
                  ),
                );
              },
            )
          : null,
    );
  }
}
