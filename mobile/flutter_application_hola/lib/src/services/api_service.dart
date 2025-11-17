import 'dart:convert';
import 'package:flutter_application_hola/src/models/Usuarios.dart';
import 'package:flutter_application_hola/src/connection/api_conection.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class ApiService {
  // Endpoints específicos para usuarios
  static String get usuariosEndpoint => ApiConnection.getUsuariosEndpoint();
  static String get loginEndpoint => ApiConnection.getLoginEndpoint();
  
  // Variable para almacenar el ID de usuario durante la sesión
  static int? _currentUserId;
  static String? _currentUserToken;

  // Método para obtener el ID del usuario actual
  static int? get currentUserId => _currentUserId;
  static String? get currentUserToken => _currentUserToken;

  // Método para inicializar la sesión desde SharedPreferences
  static Future<void> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final token = prefs.getString('userToken');
    
    if (userId != null && token != null) {
      _currentUserId = userId;
      _currentUserToken = token;
    }
  }

  // Método para limpiar la sesión
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userToken');
    _currentUserId = null;
    _currentUserToken = null;
  }

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
          'username': username,
          'nombre': nombre,
          'apellido': apellido,
          'email': email,
          'hash_contraseña': password,
          'rol': rol,
        }),
      );

      if (response.statusCode == 201) {
        return Usuario.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Error al crear usuario: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Usuario> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'hash_contraseña': password,
        }),
      );

      if (response.statusCode == 200) {
        final usuario = Usuario.fromJson(jsonDecode(response.body));
        final prefs = await SharedPreferences.getInstance();
        
        // Guardar el ID de usuario y token para la sesión
        _currentUserId = usuario.idUsuario;
        _currentUserToken = response.headers['authorization'] ?? 'token_placeholder';
        
        await prefs.setInt('userId', _currentUserId!);
        await prefs.setString('userToken', _currentUserToken!);
        
        return usuario;
      } else {
        throw Exception('Usuario o contraseña incorrectos: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  static Future<Usuario?> getUsuarioById(int idUsuario) async {
    try {
      final response = await http.get(
        Uri.parse('$usuariosEndpoint/$idUsuario'),
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
      if (password != null) updateData['password'] = password;
      if (rol != null) updateData['rol'] = rol;

      final response = await http.put(
        Uri.parse('$usuariosEndpoint/$idUsuario'),
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
        Uri.parse('$usuariosEndpoint/$idUsuario'),
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