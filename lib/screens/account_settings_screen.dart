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
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  String? _selectedGender;
  DateTime? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
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
          _phoneController.text = userData['phone'] ?? '';
          _bioController.text = userData['bio'] ?? '';
          _selectedGender = userData['gender'];
          _selectedBirthDate = userData['birthDate']?.toDate();
        });
      }
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({
            'name': _nameController.text,
            'phone': _phoneController.text,
            'bio': _bioController.text,
            'gender': _selectedGender,
            'birthDate': _selectedBirthDate,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Actualizar el nombre en Firebase Auth
          await currentUser.updateDisplayName(_nameController.text);

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
      } catch (e) {
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
      }
    }
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
      body: SingleChildScrollView(
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
              _buildProfilePicture(),
              const SizedBox(height: 24),
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
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: widget.isEnglish ? 'Phone Number' : 'Número de Teléfono',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bioController,
                label: widget.isEnglish ? 'Bio' : 'Biografía',
                icon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildGenderDropdown(),
              const SizedBox(height: 16),
              _buildBirthDatePicker(),
              const SizedBox(height: 32),
              _buildSectionTitle(
                widget.isEnglish ? 'Account Security' : 'Seguridad de la Cuenta',
              ),
              const SizedBox(height: 16),
              _buildSecurityOptions(),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _saveProfile,
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

  Widget _buildProfilePicture() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: const Color(0xFFD6E3BB),
            child: Text(
              _nameController.text.isNotEmpty
                  ? _nameController.text[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                fontSize: 40,
                color: Color(0xFF96B4D8),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF96B4D8),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: () {
                  // TODO: Implementar selección de imagen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(widget.isEnglish
                          ? 'Coming soon!'
                          : '¡Próximamente!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: widget.isEnglish ? 'Gender' : 'Género',
        prefixIcon: const Icon(Icons.wc_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: [
        DropdownMenuItem(
          value: 'male',
          child: Text(widget.isEnglish ? 'Male' : 'Masculino'),
        ),
        DropdownMenuItem(
          value: 'female',
          child: Text(widget.isEnglish ? 'Female' : 'Femenino'),
        ),
        DropdownMenuItem(
          value: 'other',
          child: Text(widget.isEnglish ? 'Other' : 'Otro'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedGender = value;
        });
      },
    );
  }

  Widget _buildBirthDatePicker() {
    return InkWell(
      onTap: () => _selectBirthDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.isEnglish ? 'Birth Date' : 'Fecha de Nacimiento',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _selectedBirthDate != null
              ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
              : widget.isEnglish
                  ? 'Select your birth date'
                  : 'Selecciona tu fecha de nacimiento',
        ),
      ),
    );
  }

  Widget _buildSecurityOptions() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: Text(widget.isEnglish ? 'Change Password' : 'Cambiar Contraseña'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // TODO: Implementar cambio de contraseña
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.isEnglish
                    ? 'Coming soon!'
                    : '¡Próximamente!'),
                backgroundColor: Colors.blue,
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.security_outlined),
          title: Text(widget.isEnglish ? 'Two-Factor Authentication' : 'Autenticación de Dos Factores'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // TODO: Implementar autenticación de dos factores
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.isEnglish
                    ? 'Coming soon!'
                    : '¡Próximamente!'),
                backgroundColor: Colors.blue,
              ),
            );
          },
        ),
      ],
    );
  }
} 