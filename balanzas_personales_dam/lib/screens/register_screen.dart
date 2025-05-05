import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/cryp.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _register() async {
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

    final prefs = await SharedPreferences.getInstance();

    // Verificar si ya existe un usuario con ese nombre
    if (prefs.containsKey('user_$username')) {
      _showMessage('Ese nombre de usuario ya existe');
      return;
    }

    // Derivar y guardar la clave para cifrado
    final key = deriveKey(password, username);
    final encodedKey = base64Encode(key);

    final allUsersJson = prefs.getString('users');
    final Map<String, String> allUsers =
        allUsersJson != null
            ? Map<String, String>.from(jsonDecode(allUsersJson))
            : {};

    if (allUsers.containsKey(username)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('El usuario ya existe')));
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registrar un nuevo usuario')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Nombre de usuario'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(labelText: 'Confirmar contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: Text('Registrar usuario'),
            ),
          ],
        ),
      ),
    );
  }
}
