import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/group.dart';
import 'group_detail_screen.dart';
import 'create_group_screen.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  void _showJoinCommunityDialog(BuildContext context) {
    final TextEditingController groupIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Unirme a Comunidad'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ingresa el código de la comunidad privada a la que deseas unirte.\n\nPara comunidades públicas, puedes unirte directamente desde la lista de comunidades.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: groupIdController,
                decoration: const InputDecoration(
                  labelText: 'Código de la comunidad privada',
                  border: OutlineInputBorder(),
                  helperText: 'Solicita el código al administrador de la comunidad',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final groupId = groupIdController.text.trim();
                if (groupId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor ingresa un código'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final groupDoc = await FirebaseFirestore.instance
                      .collection('groups')
                      .doc(groupId)
                      .get();

                  if (!groupDoc.exists) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se encontró la comunidad con ese código'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  final group = Group.fromDocument(groupDoc);
                  final currentUser = FirebaseAuth.instance.currentUser!.uid;

                  if (group.members.contains(currentUser)) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ya eres miembro de esta comunidad'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      Navigator.pop(context);
                    }
                    return;
                  }

                  if (group.pendingMembers.contains(currentUser)) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ya tienes una solicitud pendiente en esta comunidad'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      Navigator.pop(context);
                    }
                    return;
                  }

                  if (group.isPrivate) {
                    // Solicitar unirse
                    await FirebaseFirestore.instance
                        .collection('groups')
                        .doc(groupId)
                        .update({
                      'pendingMembers': FieldValue.arrayUnion([currentUser])
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Solicitud enviada. Espera la aprobación del administrador.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    // Unirse directamente
                    await FirebaseFirestore.instance
                        .collection('groups')
                        .doc(groupId)
                        .update({
                      'members': FieldValue.arrayUnion([currentUser])
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Te has unido a la comunidad exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Unirme'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Título: Comunidades
      appBar: AppBar(
        title: const Text('Comunidades'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('groups').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snapshot.data!.docs
              .map((doc) => Group.fromDocument(doc))
              .toList();

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                title: Text(group.name),
                subtitle: Text(group.description),
                trailing: ElevatedButton(
                  child: const Text('Ver'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            GroupDetailScreen(group: group),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.create),
                      title: const Text('Crear Comunidad'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CreateGroupScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.group_add),
                      title: const Text('Unirme a Comunidad'),
                      onTap: () {
                        Navigator.pop(context);
                        _showJoinCommunityDialog(context);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
} 