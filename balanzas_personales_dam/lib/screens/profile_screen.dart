import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'home_screen.dart';
import 'dashboard_screen.dart';
import '../models/transaction.dart';
import '../widgets/confirmation_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcome_screen.dart';
import 'dart:convert';
import '../utils/cryp.dart';

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

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('key');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => WelcomeScreen()),
      (route) => false,
    );
  }

  void _updateUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre de usuario no puede estar vacío')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return ConfirmationDialog(
          title: 'Actualizar nombre de usuario',
          message: '¿Deseas actualizar tu nombre de usuario?',
          onConfirm: () async {
            final prefs = await SharedPreferences.getInstance();
            final oldUsername = prefs.getString('username') ?? '';
            final oldData = prefs.getString('tx_$oldUsername');
            if (oldData != null) {
              final key = base64Decode(prefs.getString('key')!);
              final decryptedBytes = xorEncrypt(base64Decode(oldData), key);
              final decryptedJson = utf8.decode(decryptedBytes);
              final reEncrypted = base64Encode(xorEncrypt(utf8.encode(decryptedJson), key));
              await prefs.setString('tx_$newUsername', reEncrypted);
              await prefs.remove('tx_$oldUsername');
            }
            await prefs.setString('username', newUsername);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nombre de usuario actualizado')),
            );
          },
        );
      },
    );
  }

  void _updatePassword() async {
    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No dejes vacíos los campos')),
      );
      return;
    }

    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final savedKey = prefs.getString('key');

    if (username == null || savedKey == null) return;

    final derivedOldKey = base64Encode(deriveKey(current, username));
    if (derivedOldKey != savedKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actual incorrecta')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return ConfirmationDialog(
          title: 'ACTUALIZACIÓN DE CONTRASEÑA',
          message: '¿Estás seguro de que deseas actualizar tu contraseña? \nSi la olvidas, no podrás volver a acceder a tu cuenta.',
          onConfirm: () async {
            final oldKey = base64Decode(savedKey);
            final newKey = deriveKey(newPass, username);
            final oldData = prefs.getString('tx_$username');
            if (oldData != null) {
              final decryptedBytes = xorEncrypt(base64Decode(oldData), oldKey);
              final decryptedJson = utf8.decode(decryptedBytes);
              final reEncrypted = base64Encode(xorEncrypt(utf8.encode(decryptedJson), newKey));
              await prefs.setString('tx_$username', reEncrypted);
            }
            await prefs.setString('key', base64Encode(newKey));
            _currentPasswordController.clear();
            _newPasswordController.clear();
            _confirmPasswordController.clear();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contraseña actualizada correctamente')),
            );
          },
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
          const Text('Nombre de usuario', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildTextField(_usernameController, 'ROSA'),
          const SizedBox(height: 12),
          _buildMainButton('Actualizar nombre de usuario', _updateUsername),
          const SizedBox(height: 40),
          const Center(child: Text('Configuración de contraseña', style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          const Text('Contraseña actual', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildTextField(_currentPasswordController, 'Contraseña', obscure: true),
          const SizedBox(height: 12),
          const Text('Nueva contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildTextField(_newPasswordController, 'Contraseña', obscure: true),
          const SizedBox(height: 12),
          const Text('Confirma nueva contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildTextField(_confirmPasswordController, 'Contraseña', obscure: true),
          const SizedBox(height: 16),
          _buildMainButton('Actualizar contraseña', _updatePassword),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            ),
            child: const Text('Cerrar sesión', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
          }
          if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen(transactions: widget.transactions)));
          }
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool obscure = false}) {
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
    return Center(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6400CD),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
