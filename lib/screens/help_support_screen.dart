import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatefulWidget {
  final bool isEnglish;

  const HelpSupportScreen({super.key, this.isEnglish = false});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  Future<void> _launchEmail() async {
    try {
      debugPrint('Intentando abrir el email...');
      
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'support@yourapp.com',
        queryParameters: {
          'subject': widget.isEnglish ? 'Support Request' : 'Solicitud de Soporte',
          'body': widget.isEnglish 
            ? 'Hello, I need help with the following issue:'
            : 'Hola, necesito ayuda con el siguiente problema:',
        },
      );
      
      debugPrint('URI del email: $emailUri');
      
      await launchUrl(
        emailUri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      
      debugPrint('Email lanzado exitosamente');
    } catch (e) {
      debugPrint('Error al lanzar el email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEnglish 
                ? 'Could not open email app. Please try again later.'
                : 'No se pudo abrir la aplicación de correo. Por favor, inténtalo más tarde.'
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEnglish ? 'Help & Support' : 'Ayuda y Soporte'),
        backgroundColor: const Color(0xFF96B4D8),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: widget.isEnglish ? 'Frequently Asked Questions' : 'Preguntas Frecuentes',
              icon: Icons.help_outline,
              children: [
                _buildFAQItem(
                  question: widget.isEnglish ? 'How do I create a recipe?' : '¿Cómo creo una receta?',
                  answer: widget.isEnglish 
                    ? 'Go to the "Create Recipe" section and fill in all the required information about your recipe, including ingredients, steps, and cooking time.'
                    : 'Ve a la sección "Crear Receta" y completa toda la información requerida sobre tu receta, incluyendo ingredientes, pasos y tiempo de cocción.',
                ),
                _buildFAQItem(
                  question: widget.isEnglish ? 'How do I save a recipe as favorite?' : '¿Cómo guardo una receta como favorita?',
                  answer: widget.isEnglish
                    ? 'While viewing a recipe, tap the heart icon in the top right corner to add it to your favorites.'
                    : 'Mientras ves una receta, toca el icono del corazón en la esquina superior derecha para agregarla a tus favoritos.',
                ),
                _buildFAQItem(
                  question: widget.isEnglish ? 'Can I edit my recipes?' : '¿Puedo editar mis recetas?',
                  answer: widget.isEnglish
                    ? 'Yes, you can edit your own recipes from the "My Recipes" section in your profile.'
                    : 'Sí, puedes editar tus propias recetas desde la sección "Mis Recetas" en tu perfil.',
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: widget.isEnglish ? 'Contact Support' : 'Contactar Soporte',
              icon: Icons.support_agent,
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text(widget.isEnglish ? 'Email Support' : 'Soporte por Email'),
                  subtitle: Text(widget.isEnglish 
                    ? 'Get help via email'
                    : 'Obtén ayuda por correo electrónico'),
                  onTap: _launchEmail,
                ),
                ListTile(
                  leading: const Icon(Icons.chat_outlined),
                  title: Text(widget.isEnglish ? 'Live Chat' : 'Chat en Vivo'),
                  subtitle: Text(widget.isEnglish
                    ? 'Coming soon!'
                    : '¡Próximamente!'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(widget.isEnglish
                            ? 'Live chat will be available soon!'
                            : '¡El chat en vivo estará disponible pronto!'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: widget.isEnglish ? 'App Information' : 'Información de la App',
              icon: Icons.info_outline,
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(widget.isEnglish ? 'Terms of Service' : 'Términos de Servicio'),
                  onTap: () {
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
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(widget.isEnglish ? 'Privacy Policy' : 'Política de Privacidad'),
                  onTap: () {
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
                ListTile(
                  leading: const Icon(Icons.update_outlined),
                  title: Text(widget.isEnglish ? 'App Version' : 'Versión de la App'),
                  subtitle: const Text('1.0.0'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF96B4D8)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF96B4D8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: const TextStyle(
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
} 