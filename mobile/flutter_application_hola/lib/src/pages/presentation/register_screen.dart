import 'package:flutter/material.dart';
import 'package:flutter_application_hola/src/models/Usuarios.dart';
import 'package:flutter_application_hola/src/services/api_service.dart';
import 'dart:async';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _teacherCodeController = TextEditingController();
  String? _selectedRole;
  bool _isLoading = false;
  bool _showTeacherCodeField = false;
  bool _obscurePassword = true;
  
  // Estado para la disponibilidad del usuario
  Timer? _usernameDebounce;
  bool _checkingUsername = false;
  bool? _usernameAvailable;
  String _usernameMessage = '';
  
  // Lista de usuarios existentes (para verificar disponibilidad)
  List<Usuario> _usuariosExistentes = [];
  
  // Colores para la interfaz
  final Color _primaryColor = const Color(0xFF4A6FDC);
  final Color _secondaryColor = const Color(0xFF6C63FF);
  final Color _accentColor = const Color(0xFF36D1DC);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _textColor = const Color(0xFF2D3748);
  final Color _errorColor = const Color(0xFFE53E3E);
  final Color _successColor = const Color(0xFF38A169);

  // Animación
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    // Escuchar cambios en el campo de usuario
    _usernameController.addListener(_onUsernameChanged);
    
    // Cargar usuarios existentes al iniciar
    _cargarUsuariosExistentes();
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onUsernameChanged);
    _usernameDebounce?.cancel();
    _usernameController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _teacherCodeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuariosExistentes() async {
    try {
      final usuarios = await ApiService.getUsuarios();
      setState(() {
        _usuariosExistentes = usuarios;
      });
    } catch (e) {
      print('Error al cargar usuarios: $e');
    }
  }

  void _onUsernameChanged() {
    // Cancelar el timer anterior
    _usernameDebounce?.cancel();
    
    // Reiniciar estados
    setState(() {
      _usernameAvailable = null;
      _usernameMessage = '';
      _checkingUsername = false;
    });
    
    // Solo verificar si el username tiene al menos 3 caracteres
    if (_usernameController.text.length >= 3) {
      setState(() {
        _checkingUsername = true;
      });
      
      // Usar debounce para no hacer llamadas con cada tecla presionada
      _usernameDebounce = Timer(const Duration(milliseconds: 800), () {
        _checkUsernameAvailability(_usernameController.text);
      });
    }
  }

  Future<void> _checkUsernameAvailability(String username) async {
    try {
      // Verificar en la lista de usuarios existentes
      final usernameLower = username.toLowerCase().trim();
      final usuarioExistente = _usuariosExistentes.firstWhere(
        (usuario) => usuario.username.toLowerCase() == usernameLower,
        orElse: () => Usuario(
          idUsuario: 0,
          username: '',
          nombre: '',
          apellido: '',
          email: '',
          rol: '',
        ),
      );
      
      final isAvailable = usuarioExistente.username.isEmpty;
      
      setState(() {
        _checkingUsername = false;
        _usernameAvailable = isAvailable;
        _usernameMessage = isAvailable 
            ? 'Disponible'
            : 'En uso';
      });
    } catch (e) {
      setState(() {
        _checkingUsername = false;
        _usernameAvailable = null;
        _usernameMessage = 'Error al verificar';
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar disponibilidad del usuario
    if (_usernameAvailable == false) {
      _showErrorDialog(
        title: 'Usuario no disponible',
        message: 'El nombre de usuario "$_usernameController.text" ya está en uso. Por favor, elige otro.',
      );
      return;
    }

    // Validar código de docente si es necesario
    if (_selectedRole == 'Docente' && _teacherCodeController.text != '8977') {
      _showErrorDialog(
        title: 'Código Incorrecto',
        message: 'El código de docente es incorrecto. Por favor, verifica e intenta nuevamente.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String roleToSend = (_selectedRole ?? 'Alumno').toLowerCase();

      await ApiService.createUsuario(
        _usernameController.text,
        _nameController.text,
        _surnameController.text,
        _emailController.text,
        _passwordController.text,
        roleToSend,
      );

      _showSuccessDialog(
        title: '¡CUENTA CREADA!',
        message: 'Cuenta creada exitosamente',
      );
    } catch (e) {
      String errorMessage = 'Error al crear la cuenta';
      String errorType = e.toString();
      
      // Detectar errores específicos de duplicados basado en tu API
      if (errorType.contains('EMAIL_DUPLICADO')) {
        errorMessage = 'El correo electrónico ya está en uso. Por favor, usa otro correo.';
      } else if (errorType.contains('USERNAME_DUPLICADO')) {
        errorMessage = 'El nombre de usuario ya está en uso. Por favor, elige otro.';
      } else if (errorType.toLowerCase().contains('email') || 
                 errorType.toLowerCase().contains('correo')) {
        errorMessage = 'El correo electrónico ya está en uso. Por favor, usa otro correo.';
      } else if (errorType.toLowerCase().contains('username') || 
                 errorType.toLowerCase().contains('usuario')) {
        errorMessage = 'El nombre de usuario ya está en uso. Por favor, elige otro.';
      } else {
        errorMessage = 'Error: $errorType';
      }
      
      _showErrorDialog(
        title: 'Error de Registro',
        message: errorMessage,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // DIÁLOGO DE ÉXITO MEJORADO
  Future<void> _showSuccessDialog({required String title, required String message}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        _animationController.forward();
        
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _successColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono de éxito
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _successColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _successColor.withOpacity(0.3),
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 50,
                      color: _successColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Título
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _successColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Mensaje
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Botón de continuar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _animationController.reverse();
                        Navigator.of(context).pop();
                        Navigator.pushReplacementNamed(context, 'session');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Continuar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // DIÁLOGO DE ERROR MEJORADO
  Future<void> _showErrorDialog({required String title, required String message}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        _animationController.forward();
        
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _errorColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono de error
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _errorColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _errorColor.withOpacity(0.3),
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 50,
                      color: _errorColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Título
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _errorColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  
                  // Mensaje
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Botón de aceptar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _animationController.reverse();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _errorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'ENTENDIDO',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _updateRole(String? role) {
    setState(() {
      _selectedRole = role;
      _showTeacherCodeField = role == 'Docente';
      if (!_showTeacherCodeField) {
        _teacherCodeController.clear();
      }
    });
  }

  // Widget para mostrar el indicador de disponibilidad de usuario
  Widget _buildUsernameAvailabilityIndicator() {
    if (_checkingUsername) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bola de carga
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(right: 8),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
          ),
          Text(
            'Verificando...',
            style: TextStyle(
              fontSize: 12,
              color: _textColor.withOpacity(0.6),
            ),
          ),
        ],
      );
    }
    
    if (_usernameAvailable != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bola con icono - Estilo como en la imagen
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _usernameAvailable! ? _successColor.withOpacity(0.1) : _errorColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: _usernameAvailable! ? _successColor : _errorColor,
                width: 1.5,
              ),
            ),
            child: Icon(
              _usernameAvailable! ? Icons.check : Icons.close,
              size: 14,
              color: _usernameAvailable! ? _successColor : _errorColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _usernameMessage,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _usernameAvailable! ? _successColor : _errorColor,
            ),
          ),
        ],
      );
    }
    
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text('Crear una cuenta',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _textColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono y título
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 64,
                      color: _primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Completa tus datos para registrarte',
                      style: TextStyle(
                        fontSize: 16,
                        color: _textColor.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Campos de formulario
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Usuario con indicador de disponibilidad
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre de usuario',
                            labelStyle: TextStyle(color: _textColor.withOpacity(0.6)),
                            prefixIcon: Icon(Icons.person_outline_rounded, color: _primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _textColor.withOpacity(0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _primaryColor, width: 1.5),
                            ),
                            filled: true,
                            fillColor: _backgroundColor.withOpacity(0.5),
                            hintText: 'Ej: juan123',
                            suffixIcon: _checkingUsername || _usernameAvailable != null
                                ? Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: _buildUsernameAvailabilityIndicator(),
                                  )
                                : null,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, ingrese un usuario';
                            }
                            if (value.length < 3) {
                              return 'Mínimo 3 caracteres';
                            }
                            if (_usernameAvailable == false) {
                              return 'Este usuario ya está en uso';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 4),
                        // Nota informativa
                        Text(
                          'El sistema verificará si el usuario está disponible',
                          style: TextStyle(
                            fontSize: 10,
                            color: _textColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Nombre
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Primer nombre',
                        hintText: 'Solo tu primer nombre',
                        labelStyle: TextStyle(color: _textColor.withOpacity(0.6)),
                        prefixIcon: Icon(Icons.badge_outlined, color: _primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _textColor.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _primaryColor, width: 1.5),
                        ),
                        filled: true,
                        fillColor: _backgroundColor.withOpacity(0.5),
                      ),
                      validator: (value) => 
                          value == null || value.isEmpty ? 'Por favor, ingrese su nombre' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Apellido
                    TextFormField(
                      controller: _surnameController,
                      decoration: InputDecoration(
                        labelText: 'Primer apellido',
                        hintText: 'Solo tu primer apellido',
                        labelStyle: TextStyle(color: _textColor.withOpacity(0.6)),
                        prefixIcon: Icon(Icons.badge_outlined, color: _primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _textColor.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _primaryColor, width: 1.5),
                        ),
                        filled: true,
                        fillColor: _backgroundColor.withOpacity(0.5),
                      ),
                      validator: (value) => 
                          value == null || value.isEmpty ? 'Por favor, ingrese su apellido' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        labelStyle: TextStyle(color: _textColor.withOpacity(0.6)),
                        prefixIcon: Icon(Icons.email_outlined, color: _primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _textColor.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _primaryColor, width: 1.5),
                        ),
                        filled: true,
                        fillColor: _backgroundColor.withOpacity(0.5),
                        hintText: 'ejemplo@gmail.com',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingrese su correo';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Correo inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Contraseña (solo un campo)
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        labelStyle: TextStyle(color: _textColor.withOpacity(0.6)),
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: _primaryColor),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: _textColor.withOpacity(0.4),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _textColor.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _primaryColor, width: 1.5),
                        ),
                        filled: true,
                        fillColor: _backgroundColor.withOpacity(0.5),
                        hintText: 'Mínimo 6 caracteres',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingrese una contraseña';
                        }
                        if (value.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Selección de rol
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Elige tu perfil',
                        labelStyle: TextStyle(color: _textColor.withOpacity(0.6)),
                        prefixIcon: Icon(
                          _selectedRole == 'Docente' 
                            ? Icons.school_outlined 
                            : Icons.person_outline_rounded, 
                          color: _primaryColor
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _textColor.withOpacity(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _primaryColor, width: 1.5),
                        ),
                        filled: true,
                        fillColor: _backgroundColor.withOpacity(0.5),
                      ),
                      value: _selectedRole,
                      items: ['Alumno', 'Docente'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: _updateRole,
                      validator: (value) => 
                          value == null ? 'Por favor, seleccione un perfil' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de código de docente (solo visible si se selecciona Docente)
                    if (_showTeacherCodeField)
                      AnimatedOpacity(
                        opacity: _showTeacherCodeField ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: TextFormField(
                          controller: _teacherCodeController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Código de validación docente',
                            labelStyle: TextStyle(color: _textColor.withOpacity(0.6)),
                            prefixIcon: Icon(Icons.vpn_key_outlined, color: _primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _textColor.withOpacity(0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _primaryColor, width: 1.5),
                            ),
                            filled: true,
                            fillColor: _backgroundColor.withOpacity(0.5),
                          ),
                          validator: (value) {
                            if (_selectedRole == 'Docente' && (value == null || value.isEmpty)) {
                              return 'Ingrese el código de docente';
                            }
                            return null;
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: _primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        shadowColor: _primaryColor.withOpacity(0.3),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Crear cuenta',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Enlace a login
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: RichText(
                  text: TextSpan(
                    text: '¿Ya tienes una cuenta? ',
                    style: TextStyle(color: _textColor.withOpacity(0.7)),
                    children: [
                      TextSpan(
                        text: 'Inicia sesión',
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}