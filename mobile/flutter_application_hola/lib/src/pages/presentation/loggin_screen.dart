import 'package:flutter/material.dart';
import 'package:flutter_application_hola/src/pages/Student/mainstuden_Screen.dart';
import 'package:flutter_application_hola/src/pages/Teacher/mainteacher_screen.dart';
import 'package:flutter_application_hola/src/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _rememberMe = prefs.getBool('rememberMe') ?? false;
        if (_rememberMe) {
          _usernameController.text = prefs.getString('savedUsername') ?? '';
          _passwordController.text = prefs.getString('savedPassword') ?? '';
        }
      });
    } catch (e) {
      debugPrint('Error loading saved credentials: $e');
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('rememberMe', true);
      await prefs.setString('savedUsername', _usernameController.text);
      await prefs.setString('savedPassword', _passwordController.text);
    } else {
      await prefs.remove('rememberMe');
      await prefs.remove('savedUsername');
      await prefs.remove('savedPassword');
    }
  }

  // Función para guardar el nombre de usuario
  Future<void> _saveUserName(String userName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', userName);
      debugPrint('Nombre de usuario guardado: $userName');
    } catch (e) {
      debugPrint('Error guardando nombre de usuario: $e');
    }
  }

  // Función para mostrar diálogo de error mejorado
  void _showErrorDialog(String title, String message, {VoidCallback? onButtonPressed}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.shade100,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 40,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade800,
                    fontFamily: 'Roboto',
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onButtonPressed != null) {
                        onButtonPressed();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      shadowColor: Colors.indigo.withOpacity(0.4),
                    ),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showErrorDialog(
        'Campos vacíos',
        'Por favor, ingresa usuario y contraseña.',
      );
      return;
    }

    if (username.length < 4) {
      _showErrorDialog(
        'Usuario inválido',
        'El usuario debe tener al menos 4 caracteres.',
      );
      return;
    }

    if (password.length < 6) {
      _showErrorDialog(
        'Contraseña inválida',
        'La contraseña debe tener al menos 6 caracteres.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _saveCredentials();
      await ApiService.initSession();
      final usuario = await ApiService.login(username, password);

      // GUARDAR EL NOMBRE DE USUARIO EN SHAREDPREFERENCES
      // Asumiendo que tu objeto usuario tiene una propiedad 'nombre' o 'username'
      final String userNameToSave = usuario.nombre ?? 
                                   usuario.username ?? 
                                   _usernameController.text;
      
      await _saveUserName(userNameToSave);
      debugPrint('Usuario logueado: $userNameToSave');

      if (!mounted) return;

      switch (usuario.rol?.toLowerCase()) {
        case 'docente':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainTeacherScreen()),
          );
          break;
        case 'alumno':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainStudentScreen(
                userId: ApiService.currentUserId ?? 0,
                userRole: 'alumno',
              ),
            ),
          );
          break;
        default:
          await ApiService.clearSession();
          _showErrorDialog(
            'Rol no reconocido',
            'Tu cuenta no tiene un rol válido. Contacta al administrador del sistema.',
          );
      }
    } catch (e) {
      if (!mounted) return;
      await ApiService.clearSession();

      String errorMessage = 'Error al iniciar sesión';
      String errorTitle = 'Error de autenticación';

      if (e.toString().toLowerCase().contains('credenciales') ||
          e.toString().toLowerCase().contains('incorrect')) {
        errorTitle = 'Credenciales incorrectas';
        errorMessage = 'Usuario o contraseña incorrectos.';
      } else if (e.toString().toLowerCase().contains('network') ||
                 e.toString().toLowerCase().contains('conexión')) {
        errorTitle = 'Problema de conexión';
        errorMessage = 'No se pudo conectar al servidor. Por favor, verifica tu conexión a internet e intenta nuevamente.';
      } else if (e.toString().toLowerCase().contains('timeout')) {
        errorTitle = 'Tiempo de espera agotado';
        errorMessage = 'El servidor está tardando demasiado en responder. Por favor, intenta nuevamente.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }

      _showErrorDialog(errorTitle, errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 255, 255, 255),
              const Color.fromARGB(255, 218, 219, 221),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/slogosi.png',
                        width: 150,
                        height: 150,
                        errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.account_circle, size: 80, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Bienvenido a SIGEL-ITC',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[800],
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestión de inventario para laboratorios',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.indigo[800],
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Usuario',
                          hintText: 'Ej: docente123 o alumno456',
                          prefixIcon: Icon(Icons.person_outline, color: Colors.indigo[800]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.indigo[800]),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) => setState(() => _rememberMe = value!),
                                activeColor: Colors.indigo[800],
                              ),
                              Text(
                                'Recordarme',
                                style: TextStyle(color: Colors.grey.shade700, fontFamily: 'Roboto'),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              _showErrorDialog(
                                'Recuperar contraseña',
                                'Para recuperar tu contraseña, contacta al administrador del sistema.',
                              );
                            },
                            child: Text(
                              '¿Olvidaste tu contraseña?',
                              style: TextStyle(color: Colors.indigo[800], fontFamily: 'Roboto'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'INGRESAR',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, 'register');
                  },
                  child: Text(
                    '¿No tienes cuenta? Regístrate aquí',
                    style: TextStyle(
                      color: Colors.indigo[800],
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}