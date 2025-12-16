// src/services/api_service.dart

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_application_hola/src/connection/api_conection.dart';
import 'package:flutter_application_hola/src/models/Usuarios.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get usuariosEndpoint => ApiConnection.getUsuariosEndpoint();
  static String get loginEndpoint => ApiConnection.getLoginEndpoint();

  static int? _currentUserId;
  static String? _currentUserToken;

  static int? get currentUserId => _currentUserId;
  static String? get currentUserToken => _currentUserToken;

  static Future<void> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final token = prefs.getString('userToken');

    if (userId != null && token != null && token.isNotEmpty) {
      _currentUserId = userId;
      _currentUserToken = token;
    }
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userToken');
    _currentUserId = null;
    _currentUserToken = null;
  }

  // ==================== LOGIN FUNCIONAL (con hash_contraseña) ====================
  static Future<Usuario> login(String username, String password) async {
    try {
      final url = Uri.parse(loginEndpoint);
      print('LOGIN → URL: $url');
      print('LOGIN → Datos: {"username": "$username", "hash_contraseña": "******"}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'hash_contraseña': password,  // Campo exacto que espera tu backend
        }),
      ).timeout(const Duration(seconds: 20));

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        Map<String, dynamic> userData = data['user'] ?? data['usuario'] ?? data;

        final Usuario usuario = Usuario.fromJson(userData);

        // Token (si lo devuelve el backend)
        final String token = data['token'] ?? data['key'] ?? data['auth_token'] ?? '';

        _currentUserId = usuario.idUsuario;
        _currentUserToken = token.isNotEmpty ? token : null;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', _currentUserId ?? 0);
        if (_currentUserToken != null) {
          await prefs.setString('userToken', _currentUserToken!);
        }

        print('¡LOGIN EXITOSO! Usuario: ${usuario.username}');
        return usuario;
      } else {
        String errorMsg = 'Usuario o contraseña incorrectos';
        try {
          final errorBody = jsonDecode(response.body);
          errorMsg = errorBody['error'] ?? errorBody['detail'] ?? errorMsg;
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } on SocketException {
      throw Exception('Sin conexión a internet');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado');
    } catch (e) {
      print('Error en login: $e');
      throw Exception('Error: $e');
    }
  }

  // ==================== RESTO DE MÉTODOS (todos originales) ====================

  static Future<List<Usuario>> getUsuarios() async {
    try {
      final response = await http.get(Uri.parse(usuariosEndpoint));
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Usuario.fromJson(item)).toList();
      } else {
        throw Exception('Error al cargar usuarios: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Usuario> createUsuario(
    String username,
    String nombre,
    String apellido,
    String email,
    String password,
    String rol,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(usuariosEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'nombre': nombre.trim(),
          'apellido': apellido.trim(),
          'email': email.trim().toLowerCase(),
          'hash_contraseña': password,
          'rol': rol,
        }),
      );

      if (response.statusCode == 201) {
        return Usuario.fromJson(jsonDecode(response.body));
      }

      if (response.statusCode == 400 || response.statusCode == 409 || response.statusCode == 422) {
        try {
          final Map<String, dynamic> errorBody = jsonDecode(response.body);

          String mensaje = errorBody['error'] ??
                           errorBody['message'] ??
                           errorBody['msg'] ??
                           'Datos inválidos';

          String msgLower = mensaje.toLowerCase();

          if (msgLower.contains('username') || msgLower.contains('usuario')) {
            throw Exception('USERNAME_DUPLICADO');
          }
          if (msgLower.contains('email') || msgLower.contains('correo') || msgLower.contains('e-mail')) {
            throw Exception('EMAIL_DUPLICADO');
          }

          throw Exception(mensaje);
        } catch (_) {
          throw Exception(response.body);
        }
      }

      throw Exception('Error del servidor: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  static Future<Usuario?> getUsuarioById(int idUsuario) async {
    try {
      final response = await http.get(
        Uri.parse('$usuariosEndpoint$idUsuario/'),
        headers: _currentUserToken != null 
          ? {'Authorization': 'Bearer $_currentUserToken'} 
          : null,
      );
      
      if (response.statusCode == 200) {
        return Usuario.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Error al obtener usuario: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Usuario> updateUsuario(
    int idUsuario,
    {String? username,
    String? nombre,
    String? apellido,
    String? email,
    String? password,
    String? rol}
  ) async {
    try {
      final Map<String, dynamic> updateData = {};
      if (username != null) updateData['username'] = username;
      if (nombre != null) updateData['nombre'] = nombre;
      if (apellido != null) updateData['apellido'] = apellido;
      if (email != null) updateData['email'] = email;
      if (password != null) updateData['hash_contraseña'] = password;  // Consistente con creación
      if (rol != null) updateData['rol'] = rol;

      final response = await http.put(
        Uri.parse('$usuariosEndpoint$idUsuario/'),
        headers: {
          'Content-Type': 'application/json',
          if (_currentUserToken != null) 'Authorization': 'Bearer $_currentUserToken',
        },
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        return Usuario.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al actualizar usuario: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<void> deleteUsuario(int idUsuario) async {
    try {
      final response = await http.delete(
        Uri.parse('$usuariosEndpoint$idUsuario/'),
        headers: _currentUserToken != null 
          ? {'Authorization': 'Bearer $_currentUserToken'} 
          : null,
      );
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Error al eliminar usuario: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('${ApiConnection.baseUrl}/healthcheck'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}