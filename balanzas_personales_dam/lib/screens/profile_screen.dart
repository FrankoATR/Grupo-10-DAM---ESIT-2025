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
  final _usernameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  int _currentIndex = 2;

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    _username = username;
    _usernameController.text = username;
    setState(() {});
  }

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

  Future<void> _updateUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) {
      _showMessage('...');
      return;
    }

    showDialog(
      context: context,
      builder:
          (_) => ConfirmationDialog(
            title: 'Actualizar nombre de usuario',
            message: '¿Deseas actualizar tu nombre de usuario?',
            onConfirm: () async {
              final prefs = await SharedPreferences.getInstance();

              final oldUsername = prefs.getString('username') ?? '';
              final oldData = prefs.getString('tx_$oldUsername');
              if (oldData != null) {
                await prefs.setString('tx_$newUsername', oldData);
                await prefs.remove('tx_$oldUsername');
              }

              final usersJson = prefs.getString('users');
              final users =
                  usersJson != null
                      ? Map<String, String>.from(jsonDecode(usersJson))
                      : <String, String>{};

              final savedKey = prefs.getString('key')!;
              users.remove(oldUsername);
              users[newUsername] = savedKey;
              await prefs.setString('users', jsonEncode(users));

              await prefs.setString('username', newUsername);
              _username = newUsername;
              setState(() {});
              _showMessage('Nombre de usuario actualizado');
            },
          ),
    );
  }

  void _updatePassword() async {
    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showMessage('No dejes vacíos los campos');
      return;
    }

    if (newPass != confirm) {
      _showMessage('Las contraseñas no coinciden');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final savedKey = prefs.getString('key');

    if (username == null || savedKey == null) return;

    final derivedOldKey = base64Encode(deriveKey(current));
    if (derivedOldKey != savedKey) {
      _showMessage('Contraseña actual incorrecta');
      return;
    }

    showDialog(
      context: context,
      builder:
          (ctx) => ConfirmationDialog(
            title: 'Actualizar contraseña',
            message:
                '¿Estás seguro? Si la olvidas, no podrás volver a acceder.',
            onConfirm: () async {
              final prefs   = await SharedPreferences.getInstance();
              final username= prefs.getString('username')!;

              final oldKey = base64Decode(savedKey);
              final newKey = deriveKey(newPass);
              final oldData = prefs.getString('tx_$username');
              if (oldData != null) {
                final decrypted = utf8.decode(
                  xorEncrypt(base64Decode(oldData), oldKey),
                );
                final reEncrypted = base64Encode(
                  xorEncrypt(utf8.encode(decrypted), newKey),
                );
                await prefs.setString('tx_$username', reEncrypted);
              }

              final encodedNewKey = base64Encode(newKey);
              await prefs.setString('key', encodedNewKey);

              final usersJson = prefs.getString('users');
              final users     = usersJson!=null ? Map<String,String>.from(jsonDecode(usersJson)) : <String,String>{};
              users[username] = encodedNewKey;
              await prefs.setString('users', jsonEncode(users));

              _currentPasswordController.clear();
              _newPasswordController.clear();
              _confirmPasswordController.clear();
              _showMessage('Contraseña actualizada correctamente');
            },
          ),
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    VoidCallback? toggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon:
            toggleVisibility != null
                ? IconButton(
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: toggleVisibility,
                )
                : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.deepPurple),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildMainButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6400CD),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Center(
            child: Text(
              'Finanzas de ${_username.isNotEmpty ? _username : 'Usuario'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.deepPurple),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Mi perfil',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _usernameController,
                  label: 'Nombre de usuario',
                ),
                const SizedBox(height: 16),
                _buildMainButton(
                  'Actualizar nombre de usuario',
                  _updateUsername,
                ),
                const Divider(height: 40, thickness: 1),
                const Text(
                  'Cambiar contraseña',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _currentPasswordController,
                  label: 'Contraseña actual',
                  obscure: _obscureCurrent,
                  toggleVisibility:
                      () => setState(() => _obscureCurrent = !_obscureCurrent),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _newPasswordController,
                  label: 'Nueva contraseña',
                  obscure: _obscureNew,
                  toggleVisibility:
                      () => setState(() => _obscureNew = !_obscureNew),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirmar nueva contraseña',
                  obscure: _obscureConfirm,
                  toggleVisibility:
                      () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                const SizedBox(height: 16),
                _buildMainButton('Actualizar contraseña', _updatePassword),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cerrar sesión',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()),
            );
          }
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) => DashboardScreen(transactions: widget.transactions),
              ),
            );
          }
        },
      ),
    );
  }
}
