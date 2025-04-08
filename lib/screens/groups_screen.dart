import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/group.dart';
import 'group_detail_screen.dart';
import 'create_group_screen.dart';

class GroupsScreen extends StatefulWidget {
  final bool isEnglish;
  
  const GroupsScreen({super.key, this.isEnglish = false});

  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  bool get isEnglish => widget.isEnglish;

  void _showJoinCommunityDialog(BuildContext context) {
    final TextEditingController groupIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEnglish ? 'Join Community' : 'Unirme a Comunidad'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEnglish 
                  ? 'Enter the private community code you want to join.\n\nFor public communities, you can join directly from the communities list.'
                  : 'Ingresa el código de la comunidad privada a la que deseas unirte.\n\nPara comunidades públicas, puedes unirte directamente desde la lista de comunidades.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: groupIdController,
                decoration: InputDecoration(
                  labelText: isEnglish ? 'Private community code' : 'Código de la comunidad privada',
                  border: const OutlineInputBorder(),
                  helperText: isEnglish ? 'Request the code from the community administrator' : 'Solicita el código al administrador de la comunidad',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isEnglish ? 'Cancel' : 'Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final groupId = groupIdController.text.trim();
                if (groupId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEnglish ? 'Please enter a code' : 'Por favor ingresa un código'),
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
                        SnackBar(
                          content: Text(isEnglish ? 'No community found with that code' : 'No se encontró la comunidad con ese código'),
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
                        SnackBar(
                          content: Text(isEnglish ? 'You are already a member of this community' : 'Ya eres miembro de esta comunidad'),
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
                        SnackBar(
                          content: Text(isEnglish ? 'You already have a pending request in this community' : 'Ya tienes una solicitud pendiente en esta comunidad'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      Navigator.pop(context);
                    }
                    return;
                  }

                  if (group.isPrivate) {
                    await FirebaseFirestore.instance
                        .collection('groups')
                        .doc(groupId)
                        .update({
                      'pendingMembers': FieldValue.arrayUnion([currentUser])
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEnglish ? 'Request sent. Wait for administrator approval.' : 'Solicitud enviada. Espera la aprobación del administrador.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    await FirebaseFirestore.instance
                        .collection('groups')
                        .doc(groupId)
                        .update({
                      'members': FieldValue.arrayUnion([currentUser])
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEnglish ? 'You have successfully joined the community' : 'Te has unido a la comunidad exitosamente'),
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
              child: Text(isEnglish ? 'Join' : 'Unirme'),
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
        title: Text(isEnglish ? 'Communities' : 'Comunidades'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: isEnglish ? 'Search communities...' : 'Buscar comunidades...',
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
                  return Center(
                    child: Text(isEnglish ? 'No authenticated user' : 'No hay usuario autenticado')
                  );
                }

                final allGroups = snapshot.data!.docs
                    .map((doc) => Group.fromDocument(doc))
                    .where((group) =>
                        !group.isPrivate ||
                        group.members.contains(currentUser) ||
                        group.creatorId == currentUser
                    )
                    .toList();

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
                              ? isEnglish ? 'No communities available' : 'No hay comunidades disponibles'
                              : isEnglish ? 'No communities found' : 'No se encontraron comunidades',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? isEnglish 
                                ? 'Create a new community or join a private one using a code'
                                : 'Crea una nueva comunidad o únete a una privada usando un código'
                              : isEnglish
                                ? 'Try with other search terms'
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
                              builder: (context) => GroupDetailScreen(
                                group: group,
                                isEnglish: isEnglish,
                              ),
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
                      title: Text(isEnglish ? 'Create Community' : 'Crear Comunidad'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateGroupScreen(isEnglish: isEnglish),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.group_add),
                      title: Text(isEnglish ? 'Join Community' : 'Unirme a Comunidad'),
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