import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_hola/src/services/api_service.dart';

class SettingScreen extends StatefulWidget {
  final int userId;

  const SettingScreen({super.key, required this.userId});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaActualController = TextEditingController();
  final TextEditingController _nuevaContrasenaController = TextEditingController();
  final TextEditingController _confirmarContrasenaController = TextEditingController();

  bool _mostrarContrasenaActual = false;
  bool _mostrarNuevaContrasena = false;
  bool _mostrarConfirmarContrasena = false;
  bool _isLoading = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      await ApiService.initSession();
      final user = await ApiService.getUsuarioById(widget.userId);
      if (user != null && mounted) {
        setState(() {
          _nombreController.text = '${user.nombre} ${user.apellido}'.trim();
          _usuarioController.text = user.username ?? '';
          _correoController.text = user.email ?? '';
        });
      } else {
        _showErrorSnackBar('Usuario no encontrado');
      }
    } catch (e) {
      _showErrorSnackBar('Error al cargar datos: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _nombreController.dispose();
    _usuarioController.dispose();
    _correoController.dispose();
    _contrasenaActualController.dispose();
    _nuevaContrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.indigo[800],
                  flexibleSpace: FlexibleSpaceBar(
                    title: FadeTransition(
                      opacity: _fadeAnimation,
                      child: const Text(
                        'Configuración',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(1, 1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo[800]!, Colors.indigo[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Información Personal'),
                          const SizedBox(height: 16),
                          _buildProfileHeader(),
                          const SizedBox(height: 24),
                          _buildTextField(
                            controller: _nombreController,
                            label: 'Nombre Completo',
                            icon: Icons.person,
                            validator: (value) => value!.isEmpty ? 'Ingresa tu nombre' : null,
                          ),
                          _buildTextField(
                            controller: _usuarioController,
                            label: 'Nombre de Usuario',
                            icon: Icons.account_circle,
                            validator: (value) => value!.isEmpty ? 'Ingresa un usuario' : null,
                          ),
                          _buildTextField(
                            controller: _correoController,
                            label: 'Correo Electrónico',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) => !value!.contains('@') ? 'Correo inválido' : null,
                          ),
                          const SizedBox(height: 32),
                          _buildSectionTitle('Seguridad'),
                          const SizedBox(height: 16),
                          _buildPasswordField(
                            controller: _contrasenaActualController,
                            label: 'Contraseña Actual',
                            isPasswordVisible: _mostrarContrasenaActual,
                            onToggleVisibility: () =>
                                setState(() => _mostrarContrasenaActual = !_mostrarContrasenaActual),
                            validator: (value) => value!.isEmpty ? 'Ingresa tu contraseña actual' : null,
                          ),
                          _buildPasswordField(
                            controller: _nuevaContrasenaController,
                            label: 'Nueva Contraseña',
                            isPasswordVisible: _mostrarNuevaContrasena,
                            onToggleVisibility: () =>
                                setState(() => _mostrarNuevaContrasena = !_mostrarNuevaContrasena),
                            validator: (value) =>
                                value!.isNotEmpty && value.length < 6 ? 'Mínimo 6 caracteres' : null,
                          ),
                          _buildPasswordField(
                            controller: _confirmarContrasenaController,
                            label: 'Confirmar Nueva Contraseña',
                            isPasswordVisible: _mostrarConfirmarContrasena,
                            onToggleVisibility: () =>
                                setState(() => _mostrarConfirmarContrasena = !_mostrarConfirmarContrasena),
                            validator: (value) {
                              if (value!.isNotEmpty && value != _nuevaContrasenaController.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 40),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.indigo[900],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return SlideTransition(
      position: _slideAnimation,
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.indigo[200],
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.indigo[800],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nombreController.text,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _correoController.text,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.indigo[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return SlideTransition(
      position: _slideAnimation,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(
              color: Colors.indigo[900],
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: Colors.indigo[700],
                fontSize: 18,
              ),
              prefixIcon: Icon(icon, color: Colors.indigo[600]),
              suffixIcon: Icon(Icons.edit, color: Colors.indigo[400], size: 20),
              border: InputBorder.none,
              errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isPasswordVisible,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return SlideTransition(
      position: _slideAnimation,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextFormField(
            controller: controller,
            obscureText: !isPasswordVisible,
            validator: validator,
            style: TextStyle(
              color: Colors.indigo[900],
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: Colors.indigo[700],
                fontSize: 18,
              ),
              prefixIcon: Icon(Icons.lock, color: Colors.indigo[600]),
              suffixIcon: IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.indigo[400],
                ),
                onPressed: onToggleVisibility,
              ),
              border: InputBorder.none,
              errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _guardarCambios,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[600]!, Colors.green[800]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'GUARDAR CAMBIOS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _cerrarSesion,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red[400]!, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: Text(
                      'CERRAR SESIÓN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Colors.red[600],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Dividir el nombre completo en nombre y apellido
      final nombreCompleto = _nombreController.text.trim().split(' ');
      final nombre = nombreCompleto.isNotEmpty ? nombreCompleto.first : '';
      final apellido = nombreCompleto.length > 1 ? nombreCompleto.sublist(1).join(' ') : '';

      // Actualizar información personal
      await ApiService.updateUsuario(
        widget.userId,
        username: _usuarioController.text.trim(),
        nombre: nombre,
        apellido: apellido,
        email: _correoController.text.trim(),
      );

      // Actualizar contraseña si se proporcionó una nueva
      if (_nuevaContrasenaController.text.isNotEmpty) {
        // Validar contraseña actual (requiere login para verificar)
        try {
          await ApiService.login(
            _usuarioController.text.trim(),
            _contrasenaActualController.text.trim(),
          );
        } catch (e) {
          throw Exception('Contraseña actual incorrecta');
        }

        await ApiService.updateUsuario(
          widget.userId,
          password: _nuevaContrasenaController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cambios guardados exitosamente'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error al guardar cambios: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(
          'Cerrar Sesión',
          style: TextStyle(
            color: Colors.indigo[900],
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas cerrar sesión?',
          style: TextStyle(
            color: Colors.indigo[700],
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.indigo[600],
                fontSize: 16,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.clearSession();
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, 'login');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Sesión cerrada exitosamente'),
                      backgroundColor: Colors.red[600],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  _showErrorSnackBar('Error al cerrar sesión: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}