import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/group.dart';
import 'group_detail_screen.dart';
import 'create_group_screen.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({Key? key}) : super(key: key);

  void _showJoinCommunityDialog(BuildContext context) {
    final TextEditingController _groupIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Unirme a Comunidad'),
          content: TextField(
            controller: _groupIdController,
            decoration: const InputDecoration(
              labelText: 'Código de la comunidad',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final groupId = _groupIdController.text.trim();
                if (groupId.isNotEmpty) {
                  try {
                    final groupDoc = await FirebaseFirestore.instance
                        .collection('groups')
                        .doc(groupId)
                        .get();
                    if (groupDoc.exists) {
                      final currentUser =
                          FirebaseAuth.instance.currentUser!.uid;
                      await FirebaseFirestore.instance
                          .collection('groups')
                          .doc(groupId)
                          .update({
                        'members': FieldValue.arrayUnion([currentUser])
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('¡Te has unido a la comunidad!'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Código de comunidad inválido'),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                  Navigator.pop(context);
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