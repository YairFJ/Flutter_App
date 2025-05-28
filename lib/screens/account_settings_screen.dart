import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountSettingsScreen extends StatefulWidget {
  final bool isEnglish;

  const AccountSettingsScreen({super.key, this.isEnglish = false});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _emailController.text = currentUser.email ?? '';
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          // Primero actualizar en Firebase Auth
          try {
            await currentUser.updateDisplayName(_nameController.text.trim());
          } catch (e) {
            print('Error updating display name: $e');
            // Continuar con la actualización en Firestore incluso si falla la actualización del display name
          }

          // Luego actualizar en Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .set({
            'name': _nameController.text.trim(),
            'email': currentUser.email,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          // Actualizar el nombre en todas las recetas del usuario
          final recipesQuery = await FirebaseFirestore.instance
              .collection('recipes')
              .where('userId', isEqualTo: currentUser.uid)
              .get();

          final batch = FirebaseFirestore.instance.batch();
          for (var doc in recipesQuery.docs) {
            batch.update(doc.reference, {
              'creatorName': _nameController.text.trim(),
            });
          }
          await batch.commit();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.isEnglish
                    ? 'Profile updated successfully'
                    : 'Perfil actualizado con éxito'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } on FirebaseException catch (e) {
        print('Firebase error: ${e.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEnglish
                  ? 'Error updating profile: ${e.message}'
                  : 'Error al actualizar el perfil: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (e is TypeError) {
          // Ignorar el error
        } else {
          rethrow;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEnglish
                  ? 'Error updating profile'
                  : 'Error al actualizar el perfil'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isEnglish ? 'Change Password' : 'Cambiar Contraseña'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: widget.isEnglish ? 'Current Password' : 'Contraseña Actual',
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: widget.isEnglish ? 'New Password' : 'Nueva Contraseña',
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: widget.isEnglish ? 'Confirm New Password' : 'Confirmar Nueva Contraseña',
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.isEnglish ? 'Cancel' : 'Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (_newPasswordController.text != _confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(widget.isEnglish
                        ? 'New passwords do not match'
                        : 'Las contraseñas nuevas no coinciden'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null && user.email != null) {
                  // Reautenticar al usuario
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: _currentPasswordController.text,
                  );
                  try {
                    await user.reauthenticateWithCredential(credential);
                  } catch (e) {
                    if (e is TypeError) {
                      // Ignorar el error de tipo que ocurre con PigeonUserDetails
                    } else {
                      rethrow;
                    }
                  }

                  // Cambiar la contraseña
                  try {
                    await user.updatePassword(_newPasswordController.text);
                  } catch (e) {
                    if (e is TypeError) {
                      // Ignorar el error de tipo que ocurre con PigeonUserInfo
                    } else {
                      rethrow;
                    }
                  }

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(widget.isEnglish
                            ? 'Password updated successfully'
                            : 'Contraseña actualizada con éxito'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } on FirebaseAuthException catch (e) {
                String message;
                if (e.code == 'wrong-password') {
                  message = widget.isEnglish
                      ? 'Current password is incorrect'
                      : 'La contraseña actual es incorrecta';
                } else if (e.code == 'user-mismatch' || e.code == 'invalid-credential') {
                  message = widget.isEnglish
                      ? 'You cannot change the password for this account. If you used Google, Apple or another social method, you must change the password from that provider.'
                      : 'No puedes cambiar la contraseña de esta cuenta. Si usaste Google, Apple u otro método social, debes cambiar la contraseña desde ese proveedor.';
                } else if (e.code == 'weak-password') {
                  message = widget.isEnglish
                      ? 'The password is too weak'
                      : 'La contraseña es demasiado débil';
                } else {
                  message = widget.isEnglish
                      ? 'Error changing password: e.message'
                      : 'Error al cambiar la contraseña: e.message';
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(widget.isEnglish ? 'Change' : 'Cambiar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEnglish ? 'Account Settings' : 'Configuración de Cuenta'),
        backgroundColor: const Color(0xFF96B4D8),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 24 : 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(
                    widget.isEnglish ? 'Personal Information' : 'Información Personal',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _nameController,
                    label: widget.isEnglish ? 'Full Name' : 'Nombre Completo',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return widget.isEnglish
                            ? 'Please enter your name'
                            : 'Por favor ingresa tu nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _emailController,
                    label: widget.isEnglish ? 'Email' : 'Correo Electrónico',
                    icon: Icons.email_outlined,
                    enabled: false,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(
                    widget.isEnglish ? 'Account Security' : 'Seguridad de la Cuenta',
                  ),
                  const SizedBox(height: 16),
                  _buildSecurityOptions(),
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF96B4D8),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 48 : 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.isEnglish ? 'Save Changes' : 'Guardar Cambios',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF96B4D8),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF96B4D8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF96B4D8), width: 2),
        ),
      ),
    );
  }

  Widget _buildSecurityOptions() {
    return Column(
      children: [
        // Todas las opciones de seguridad han sido eliminadas
      ],
    );
  }
} 