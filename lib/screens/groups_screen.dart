import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/group.dart';
import 'group_detail_screen.dart';
import 'create_group_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidades'),
      ),
      body: Column(
        children: [
          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar comunidades...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('groups').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final currentUser = FirebaseAuth.instance.currentUser?.uid;
                if (currentUser == null) {
                  return const Center(child: Text('No hay usuario autenticado'));
                }

                final allGroups = snapshot.data!.docs
                    .map((doc) => Group.fromDocument(doc))
                    .where((group) =>
                        !group.isPrivate || // Mostrar todas las comunidades públicas
                        group.members.contains(currentUser) || // Mostrar comunidades privadas donde soy miembro
                        group.creatorId == currentUser // Mostrar comunidades privadas donde soy creador
                    )
                    .toList();

                // Filtrar grupos solo por nombre
                final groups = _searchQuery.isEmpty
                    ? allGroups
                    : allGroups.where((group) =>
                        group.name.toLowerCase().contains(_searchQuery)).toList();

                if (groups.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.group_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No hay comunidades disponibles'
                              : 'No se encontraron comunidades',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Crea una nueva comunidad o únete a una privada usando un código'
                              : 'Intenta con otros términos de búsqueda',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(group.name),
                        subtitle: Text(group.description ?? ''),
                        trailing: group.members.contains(FirebaseAuth.instance.currentUser?.uid)
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupDetailScreen(group: group),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
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
                            builder: (context) => const CreateGroupScreen(),
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