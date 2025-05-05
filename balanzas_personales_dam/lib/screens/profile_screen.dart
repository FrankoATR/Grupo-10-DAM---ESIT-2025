import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'home_screen.dart';
import 'dashboard_screen.dart';
import '../models/transaction.dart';
import '../widgets/confirmation_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final List<Transaction> transactions;

  ProfileScreen({required this.transactions});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _usernameController = TextEditingController(text: 'ROSA');
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  int _currentIndex = 2;




  void _updateUsername() {
    final current = _usernameController.text;

    if (current.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre de usuario no puede estar vacío')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return ConfirmationDialog(
          title: 'Eliminar dato',
          message: '¿Estás seguro de que deseas eliminar este dato?',
          onConfirm: () => print('Nuevo nombre de usuario: ${_usernameController.text}'),
        );
      },
    );
  }

  void _updatePassword() {
    final current = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No dejes vacios los campos')),
      );
      return;
    }


    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return ConfirmationDialog(
          title: 'Eliminar dato',
          message: '¿Estás seguro de que deseas eliminar este dato?',
          onConfirm: () => print('Contraseña actual: $current, Nueva contraseña: $newPass'),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        children: [
          Center(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.deepPurple),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'Mi perfil',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Nombre de usuario
          const Text(
            'Nombre de usuario',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildTextField(_usernameController, 'ROSA'),
          const SizedBox(height: 12),
          _buildMainButton('Actualizar nombre de usuario', _updateUsername),
          const SizedBox(height: 40),

          // Actualizar contraseña
          const Center(
            child: Text(
              'Actualizar contraseña',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Contraseña actual',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            _currentPasswordController,
            'Contraseña',
            obscure: true,
          ),
          const SizedBox(height: 12),
          const Text(
            'Nueva contraseña',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildTextField(_newPasswordController, 'Contraseña', obscure: true),
          const SizedBox(height: 12),
          const Text(
            'Confirma nueva contraseña',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            _confirmPasswordController,
            'Contraseña',
            obscure: true,
          ),
          const SizedBox(height: 16),
          _buildMainButton('Actualizar contraseña', _updatePassword),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          }
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen(transactions: widget.transactions)),
            );
          }
        },
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.deepPurple),
        ),
      ),
    );
  }

  Widget _buildMainButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6400CD),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
