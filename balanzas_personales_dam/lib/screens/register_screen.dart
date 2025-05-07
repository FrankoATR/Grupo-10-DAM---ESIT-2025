import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/cryp.dart';
import 'login_screen.dart';
import '../widgets/confirmation_dialog.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final prefs = await SharedPreferences.getInstance();

    final allUsersJson = prefs.getString('users');
    final Map<String, String> allUsers =
        allUsersJson != null
            ? Map<String, String>.from(jsonDecode(allUsersJson))
            : {};

    if (allUsers.containsKey(username)) {
      _showMessage('Ese nombre de usuario ya existe');
      return;
    }

    final key = deriveKey(password);
    final encodedKey = base64Encode(key);

    allUsers[username] = encodedKey;
    await prefs.setString('users', jsonEncode(allUsers));
    await prefs.setString('username', username);
    await prefs.setString('key', encodedKey);

    _showMessage('Usuario registrado con éxito');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  void _showSecurityWarning() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Todos los campos son obligatorios');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Las contraseñas no coinciden');
      return;
    }

    showDialog(
      context: context,
      builder:
          (_) => ConfirmationDialog(
            title: 'AVISO DE SEGURIDAD',
            message:
                'Esta aplicación cuenta con almacenamiento cifrado de datos, al registrar un nuevo usuario, no tendrá forma de recuperar su contraseña en caso de olvidarla. Únicamente puede ser restablecida ingresando a la cuenta. Por lo tanto, si olvidaste tu contraseña, te recomendamos eliminar tus datos.',
            onConfirm: _register,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar un nuevo usuario'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      Image.asset('assets/images/Logo.png', height: 120),
                      const SizedBox(height: 30),
                      _buildTextField(
                        controller: _usernameController,
                        label: 'Usuario',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Contraseña',
                        obscure: _obscurePassword,
                        toggleVisibility: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirmar contraseña',
                        obscure: _obscureConfirm,
                        toggleVisibility: () {
                          setState(() => _obscureConfirm = !_obscureConfirm);
                        },
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _showSecurityWarning,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6400CD),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Registrar usuario',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.only(top: 30, bottom: 10),
                        child: Text.rich(
                          TextSpan(
                            text: 'Al utilizar FinanzasDAMSV, acepta los\n',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                            children: [
                              TextSpan(
                                text: 'Términos y Políticas de Privacidad.',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
