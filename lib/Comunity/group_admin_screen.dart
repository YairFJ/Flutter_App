import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/group.dart';
import '../services/language_service.dart';

class GroupAdminScreen extends StatefulWidget {
  final Group group;

  const GroupAdminScreen({super.key, required this.group});

  @override
  State<GroupAdminScreen> createState() => _GroupAdminScreenState();
}

class _GroupAdminScreenState extends State<GroupAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isPrivate = false;
  bool _isLoading = false;
  late bool isEnglish;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _descriptionController = TextEditingController(text: widget.group.description);
    _isPrivate = widget.group.isPrivate;
    isEnglish = Provider.of<LanguageService>(context, listen: false).isEnglish;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newIsEnglish = Provider.of<LanguageService>(context).isEnglish;
    if (isEnglish != newIsEnglish) {
      setState(() {
        isEnglish = newIsEnglish;
      });
    }
  }

  String getText(String spanish, String english) {
    return isEnglish ? english : spanish;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _updateGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.id)
          .update({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isPrivate': _isPrivate,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getText('Comunidad actualizada exitosamente', 'Community updated successfully')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getText('Error al actualizar la comunidad: ', 'Error updating community: ') + e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getText('Eliminar Comunidad', 'Delete Community')),
        content: Text(
          getText(
            '¿Estás seguro de que deseas eliminar esta comunidad? Esta acción no se puede deshacer.',
            'Are you sure you want to delete this community? This action cannot be undone.'
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(getText('Cancelar', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(getText('Eliminar', 'Delete')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final recipesSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.id)
          .collection('recipes')
          .get();

      for (var doc in recipesSnapshot.docs) {
        await doc.reference.delete();
      }

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.id)
          .delete();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/groups', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getText('Comunidad eliminada exitosamente', 'Community deleted successfully')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getText('Error al eliminar la comunidad: ', 'Error deleting community: ') + e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeMember(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.id)
          .update({
        'members': FieldValue.arrayRemove([userId]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getText('Usuario removido exitosamente', 'User removed successfully')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getText('Error al remover al usuario: ', 'Error removing user: ') + e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptMember(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.id)
          .update({
        'members': FieldValue.arrayUnion([userId]),
        'pendingMembers': FieldValue.arrayRemove([userId]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getText('Usuario aceptado exitosamente', 'User accepted successfully')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getText('Error al aceptar al usuario: ', 'Error accepting user: ') + e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectMember(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.group.id)
          .update({
        'pendingMembers': FieldValue.arrayRemove([userId]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getText('Solicitud rechazada', 'Request rejected')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getText('Error al rechazar la solicitud: ', 'Error rejecting request: ') + e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getText('Administrar Comunidad', 'Manage Community')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : _deleteGroup,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: getText('Nombre de la comunidad', 'Community Name'),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return getText('Por favor ingresa un nombre', 'Please enter a name');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: getText('Descripción', 'Description'),
                            border: const OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return getText('Por favor ingresa una descripción', 'Please enter a description');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: Text(getText('Comunidad Privada', 'Private Community')),
                          subtitle: Text(
                            _isPrivate
                                ? getText('Los usuarios deben solicitar unirse', 'Users must request to join')
                                : getText('Cualquiera puede unirse', 'Anyone can join'),
                          ),
                          value: _isPrivate,
                          onChanged: (value) {
                            setState(() => _isPrivate = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _updateGroup,
                          child: Text(getText('Guardar Cambios', 'Save Changes')),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 32),
                  // Sección del código de la comunidad (solo para comunidades privadas)
                  if (_isPrivate) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getText('Código de la Comunidad', 'Community Code'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.group.id,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(text: widget.group.id));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(getText('Código copiado al portapapeles', 'Code copied to clipboard')),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              getText(
                                'Comparte este código con otros usuarios para que puedan unirse a la comunidad.',
                                'Share this code with other users so they can join the community.'
                              ),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 32),
                  ],
                  Text(
                    getText('Solicitudes Pendientes', 'Pending Requests'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('groups')
                        .doc(widget.group.id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final group = Group.fromDocument(snapshot.data!);
                      if (group.pendingMembers.isEmpty) {
                        return Card(
                          child: ListTile(
                            title: Text(getText('No hay solicitudes pendientes', 'No pending requests')),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: group.pendingMembers.length,
                        itemBuilder: (context, index) {
                          final userId = group.pendingMembers[index];
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return ListTile(
                                  title: Text(getText('Cargando...', 'Loading...')),
                                );
                              }

                              final userData =
                                  snapshot.data!.data() as Map<String, dynamic>?;
                              final userName = userData?['name'] ?? getText('Usuario', 'User');
                              final userEmail = userData?['email'] ?? getText('No disponible', 'Not available');

                              return Card(
                                child: ListTile(
                                  title: Text(userName),
                                  subtitle: Text(userEmail),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check),
                                        color: Colors.green,
                                        onPressed: () => _acceptMember(userId),
                                        tooltip: getText('Aceptar', 'Accept'),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        color: Colors.red,
                                        onPressed: () => _rejectMember(userId),
                                        tooltip: getText('Rechazar', 'Reject'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  const Divider(height: 32),
                  Text(
                    getText('Miembros', 'Members'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('groups')
                        .doc(widget.group.id)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final group = Group.fromDocument(snapshot.data!);
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: group.members.length,
                        itemBuilder: (context, index) {
                          final userId = group.members[index];
                          final isCreator = group.isCreator(userId);

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .get(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const ListTile(
                                  title: Text('Cargando...'),
                                );
                              }

                              final userData =
                                  snapshot.data!.data() as Map<String, dynamic>?;
                              final userName = userData?['name'] ?? 'Usuario';
                              final userEmail = userData?['email'] ?? 'No disponible';

                              return Card(
                                child: ListTile(
                                  title: Text(userName),
                                  subtitle: Text(userEmail),
                                  trailing: isCreator
                                      ? const Chip(
                                          label: Text('Creador'),
                                          backgroundColor: Colors.blue,
                                          labelStyle: TextStyle(color: Colors.white),
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.remove_circle),
                                          color: Colors.red,
                                          onPressed: () => _removeMember(userId),
                                        ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
} 