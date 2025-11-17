import 'package:flutter/material.dart';
import 'package:flutter_application_hola/src/models/TaskStatus.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_application_hola/src/services/api_task_services.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class TaskScreen extends StatefulWidget {
  final Task task;
  final int userId;
  final int taskId;
  final String userRole;

  const TaskScreen({
    super.key,
    required this.task,
    required this.userId,
    required this.taskId,
    required this.userRole,
  });

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _comentariosController = TextEditingController();
  final ApiTaskServices _apiService = ApiTaskServices();
  bool _isSubmitting = false;
  String _errorMessage = '';
  File? _archivoAdjunto;
  TaskStatus _currentStatus = TaskStatus.pending;
  Map<String, dynamic>? _userDelivery;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _checkDeliveryStatus();
    
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
  }

  @override
  void dispose() {
    _comentariosController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _checkDeliveryStatus() {
    final userDelivery = widget.task.deliveries.firstWhere(
      (delivery) => delivery['id_alumno'] == widget.userId,
      orElse: () => {},
    );
    if (userDelivery.isNotEmpty) {
      setState(() {
        _currentStatus = TaskStatus.delivered;
        _userDelivery = userDelivery;
        _comentariosController.text = userDelivery['observaciones'] ?? '';
      });
    }
  }

  bool _isDeliveryOnTime(Map<String, dynamic> delivery) {
    if (delivery['fecha_entrega'] == null) return false;
    final deliveryDate = DateTime.parse(delivery['fecha_entrega']);
    final dueDateTime = DateTime(
      widget.task.dueDate.year,
      widget.task.dueDate.month,
      widget.task.dueDate.day,
      widget.task.dueTime != null
          ? int.parse(widget.task.dueTime!.split(':')[0])
          : 23,
      widget.task.dueTime != null
          ? int.parse(widget.task.dueTime!.split(':')[1])
          : 59,
    );
    return deliveryDate.isBefore(dueDateTime) || deliveryDate.isAtSameMomentAs(dueDateTime);
  }

  Future<void> _agregarArchivo() async {
    if (_archivoAdjunto != null) {
      _showCustomNotification(
        title: 'Atención',
        message: 'Solo se permite un archivo por entrega',
        type: 'warning',
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        bool? confirmado = await _showFileConfirmationDialog(
          fileName: result.files.single.name,
        );
        
        if (confirmado == true) {
          setState(() {
            _archivoAdjunto = File(result.files.single.path!);
          });
          // No mostrar notificación de "archivo agregado"
        }
      }
    } catch (e) {
      _showCustomNotification(
        title: 'Error',
        message: 'Error al seleccionar archivo',
        type: 'error',
      );
    }
  }

  // DIÁLOGO DE CONFIRMACIÓN PARA SUBIR ARCHIVO
  Future<bool?> _showFileConfirmationDialog({required String fileName}) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.attach_file,
                    size: 40,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Título
                Text(
                  '¿Subir este archivo?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Nombre del archivo
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Mensaje
                Text(
                  '¿Estás seguro de que deseas subir este archivo para tu entrega?',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                
                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text(
                          'CANCELAR',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'SUBIR',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _descargarArchivoTarea(String resourceType, int resourceId, String fileName) async {
    try {
      final file = await _apiService.downloadFile(
        resourceType: resourceType,
        resourceId: resourceId,
        fileName: fileName,
      );
      _showSuccessDialog(
        title: '¡Descarga Exitosa!',
        message: 'El archivo se ha descargado correctamente',
      );
      await OpenFile.open(file.path);
    } catch (e) {
      _showErrorDialog(
        title: 'Error en Descarga',
        message: 'No se pudo descargar el archivo',
      );
    }
  }

  Future<void> _eliminarEntrega() async {
    if (_userDelivery == null || _userDelivery!['id_entrega'] == null) {
      _showCustomNotification(
        title: 'Error',
        message: 'No hay entrega para eliminar',
        type: 'error',
      );
      return;
    }

    if (widget.task.isExpired && widget.userRole == 'alumno') {
      _showCustomNotification(
        title: 'Error',
        message: 'No puedes modificar entregas de tareas expiradas',
        type: 'error',
      );
      return;
    }

    bool? confirmado = await _showConfirmationDialog(
      title: 'Eliminar Entrega',
      message: '¿Estás seguro de que deseas eliminar tu entrega? Esta acción no se puede deshacer.',
      confirmText: 'ELIMINAR',
      cancelText: 'CANCELAR',
      isDestructive: true,
    );

    if (confirmado != true) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      await _apiService.deleteDelivery(_userDelivery!['id_entrega']);
      setState(() {
        _currentStatus = TaskStatus.pending;
        _userDelivery = null;
        _archivoAdjunto = null;
        _comentariosController.clear();
      });
      _showSuccessDialog(
        title: '¡Eliminado!',
        message: 'Tu entrega ha sido eliminada correctamente',
      );
      if (mounted) {
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al eliminar entrega: $e';
      });
      _showErrorDialog(
        title: 'Error al Eliminar',
        message: 'No se pudo eliminar la entrega',
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _enviarTarea() async {
    if (_archivoAdjunto == null) {
      _showCustomNotification(
        title: 'Atención',
        message: 'Debes adjuntar un archivo para enviar la tarea',
        type: 'warning',
      );
      return;
    }

    if (widget.task.isExpired && widget.userRole == 'alumno') {
      _showCustomNotification(
        title: 'Error',
        message: 'No puedes enviar tareas expiradas',
        type: 'error',
      );
      return;
    }

    bool? confirmado = await _showConfirmationDialog(
      title: _currentStatus == TaskStatus.delivered ? 'Actualizar Entrega' : 'Enviar Tarea',
      message: _currentStatus == TaskStatus.delivered 
          ? '¿Estás seguro de que deseas actualizar tu entrega?'
          : '¿Estás seguro de que deseas enviar tu tarea?',
      confirmText: _currentStatus == TaskStatus.delivered ? 'ACTUALIZAR' : 'ENVIAR',
      cancelText: 'CANCELAR',
      isDestructive: false,
    );

    if (confirmado != true) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      if (_currentStatus == TaskStatus.delivered && _userDelivery != null) {
        await _apiService.updateDelivery(
          deliveryId: _userDelivery!['id_entrega'],
          archivo: _archivoAdjunto,
          observaciones: _comentariosController.text.isNotEmpty
              ? _comentariosController.text
              : 'Actualización desde la app',
        );
        _showSuccessDialog(
          title: '¡Actualizado!',
          message: 'Tu entrega ha sido actualizada correctamente',
        );
      } else {
        await _apiService.createDelivery(
          taskId: widget.taskId,
          alumnoId: widget.userId,
          archivo: _archivoAdjunto,
          observaciones: _comentariosController.text.isNotEmpty
              ? _comentariosController.text
              : 'Entrega desde la app',
        );
        setState(() {
          _currentStatus = TaskStatus.delivered;
        });
        _showSuccessDialog(
          title: '¡Éxito!',
          message: 'Tu tarea ha sido enviada correctamente',
        );
      }
      if (mounted) {
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al enviar tarea: $e';
      });
      _showErrorDialog(
        title: 'Error al Enviar',
        message: 'No se pudo enviar la tarea. Intenta nuevamente.',
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // DIÁLOGO DE ÉXITO - ESTILO ACTUALIZADO
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
                    color: Colors.green.withOpacity(0.3),
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
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green.shade200,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 50,
                      color: Colors.green.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Título
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
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
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
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

  // DIÁLOGO DE ERROR - ESTILO ACTUALIZADO
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
                    color: Colors.red.withOpacity(0.3),
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
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red.shade200,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Título
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
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
                        backgroundColor: Colors.red.shade600,
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

  // DIÁLOGO DE CONFIRMACIÓN MEJORADO
  Future<bool?> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
    required bool isDestructive,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDestructive 
                        ? Colors.red.shade50 
                        : Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDestructive ? Icons.warning_amber : Icons.help_outline,
                    color: isDestructive 
                        ? Colors.red.shade600 
                        : Colors.blue.shade600,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Título
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDestructive 
                        ? Colors.red.shade800 
                        : Colors.blue.shade800,
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
                const SizedBox(height: 28),
                
                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          cancelText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDestructive 
                              ? Colors.red.shade600 
                              : Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // NOTIFICACIONES FLOTANTES MEJORADAS
  void _showCustomNotification({
    required String title,
    required String message,
    required String type, // 'success', 'error', 'warning'
  }) {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case 'success':
        backgroundColor = Colors.green.shade600;
        icon = Icons.check_circle;
        break;
      case 'error':
        backgroundColor = Colors.red.shade600;
        icon = Icons.error;
        break;
      case 'warning':
        backgroundColor = Colors.orange.shade600;
        icon = Icons.warning;
        break;
      default:
        backgroundColor = Colors.blue.shade600;
        icon = Icons.info;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 4),
        elevation: 8,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  String _calcularTiempoRestante() {
    final ahora = DateTime.now();
    DateTime dueDateTime = widget.task.dueDate;

    if (widget.task.dueTime != null) {
      try {
        final timeParts = widget.task.dueTime!.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        dueDateTime = DateTime(
          widget.task.dueDate.year,
          widget.task.dueDate.month,
          widget.task.dueDate.day,
          hour,
          minute,
        );
      } catch (e) {
        dueDateTime = widget.task.dueDate.add(const Duration(hours: 23, minutes: 59));
      }
    }

    final diferencia = dueDateTime.difference(ahora);

    if (diferencia.isNegative) {
      return 'Tiempo expirado';
    } else if (diferencia.inDays > 0) {
      return '${diferencia.inDays} días ${diferencia.inHours.remainder(24)} horas';
    } else if (diferencia.inHours > 0) {
      return '${diferencia.inHours} horas ${diferencia.inMinutes.remainder(60)} minutos';
    } else if (diferencia.inMinutes > 0) {
      return '${diferencia.inMinutes} minutos';
    } else {
      return 'Menos de 1 minuto';
    }
  }

  void _eliminarArchivo() {
    setState(() {
      _archivoAdjunto = null;
    });
    _showCustomNotification(
      title: 'Archivo Eliminado',
      message: 'El archivo ha sido removido de tu entrega',
      type: 'success',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      appBar: AppBar(
        title: const Text(
          'Entrega de Tarea',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade800, Colors.indigo.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isSubmitting
          ? _buildLoadingScreen()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTaskHeaderCard(),
                  const SizedBox(height: 20),
                  _buildInstructionsSection(),
                  const SizedBox(height: 20),
                  _buildDeliveryDetailsSection(),
                  const SizedBox(height: 20),
                  _buildAttachmentsSection(),
                  const SizedBox(height: 20),
                  _buildCommentsSection(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.indigo.shade200,
                width: 2,
              ),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Procesando tu solicitud...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.indigo.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Por favor espera un momento',
            style: TextStyle(
              fontSize: 14,
              color: Colors.indigo.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.assignment, color: Colors.indigo.shade800, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tarea asignada',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.indigo.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.task.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Fecha de entrega:',
            value: _formatDueDateTime(),
            valueColor: widget.task.dueDate.isBefore(DateTime.now())
                ? Colors.red.shade600
                : Colors.indigo.shade800,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.person,
            label: 'Creador:',
            value: widget.task.creator,
            valueColor: Colors.indigo.shade800,
          ),
        ],
      ),
    );
  }

  String _formatDueDateTime() {
    DateTime dueDateTime = widget.task.dueDate;
    if (widget.task.dueTime != null) {
      try {
        final timeParts = widget.task.dueTime!.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        dueDateTime = DateTime(
          widget.task.dueDate.year,
          widget.task.dueDate.month,
          widget.task.dueDate.day,
          hour,
          minute,
        );
      } catch (e) {
        // Fallback to date only if time parsing fails
      }
    }
    return DateFormat('dd MMMM yyyy - hh:mm a').format(dueDateTime);
  }

  Widget _buildInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instrucciones',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.05),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.task.description ?? 'Sin descripción proporcionada',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalles de Entrega',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade800,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailItem(
          icon: Icons.access_time,
          title: 'Tiempo restante:',
          value: _calcularTiempoRestante(),
          valueColor: widget.task.dueDate.isBefore(DateTime.now().add(const Duration(days: 1)))
              ? Colors.orange.shade700
              : Colors.indigo.shade800,
          iconColor: Colors.orange.shade600,
        ),
        _buildDetailItem(
          icon: Icons.assignment_turned_in,
          title: 'Estatus de entrega:',
          value: _currentStatus == TaskStatus.pending
              ? 'Pendiente de entrega'
              : _userDelivery != null && _isDeliveryOnTime(_userDelivery!) ? 'Entregado a tiempo' : 'Entregado tarde',
          valueColor: _currentStatus == TaskStatus.pending
              ? Colors.orange.shade700
              : (_userDelivery != null && _isDeliveryOnTime(_userDelivery!) ? Colors.green.shade700 : Colors.orange.shade700),
          iconColor: _currentStatus == TaskStatus.pending
              ? Colors.orange.shade600
              : (_userDelivery != null && _isDeliveryOnTime(_userDelivery!) ? Colors.green.shade600 : Colors.orange.shade600),
        ),
        if (_userDelivery != null && _userDelivery!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDetailItem(
            icon: Icons.star,
            title: 'Calificación:',
            value: _userDelivery!['calificacion'] ?? 'Sin calificar',
            valueColor: Colors.indigo.shade800,
            iconColor: Colors.yellow.shade600,
          ),
          if (_userDelivery!['observaciones'] != null &&
              _userDelivery!['observaciones'] != 'Sin observaciones') ...[
            const SizedBox(height: 12),
            _buildDetailItem(
              icon: Icons.comment,
              title: 'Observaciones:',
              value: _userDelivery!['observaciones'],
              valueColor: Colors.indigo.shade800,
              iconColor: Colors.indigo.shade600,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Archivos Adjuntos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade800,
          ),
        ),
        const SizedBox(height: 12),
        // Archivo de la tarea
        if (widget.task.filePath != null && widget.task.filePath != 'Sin archivo')
          _buildAttachmentItem(
            filename: widget.task.filePath!.split('/').last,
            onDownload: () => _descargarArchivoTarea(
              'tarea',
              widget.taskId,
              widget.task.filePath!.split('/').last,
            ),
            label: 'Archivo de la tarea',
          ),
        // Archivo de la entrega del alumno
        if (_userDelivery != null &&
            _userDelivery!['archivo_ruta'] != null &&
            _userDelivery!['archivo_ruta'] != 'Sin archivo')
          _buildAttachmentItem(
            filename: _userDelivery!['archivo_ruta'].split('/').last,
            onDownload: () => _descargarArchivoTarea(
              'entrega',
              _userDelivery!['id_entrega'],
              _userDelivery!['archivo_ruta'].split('/').last,
            ),
            onRemove: widget.userRole == 'alumno' && !widget.task.isExpired ? _eliminarEntrega : null,
            label: 'Tu entrega',
          ),
        // Archivo seleccionado para subir
        if (_archivoAdjunto != null)
          _buildAttachmentItem(
            filename: _archivoAdjunto!.path.split('/').last,
            onRemove: widget.userRole == 'alumno' && !widget.task.isExpired ? _eliminarArchivo : null,
            label: 'Archivo para enviar',
          ),
        if (widget.task.filePath == null && _userDelivery == null && _archivoAdjunto == null)
          _buildEmptyAttachments(),
        const SizedBox(height: 12),
        if (widget.userRole == 'alumno' && !widget.task.isExpired) _buildAddFileButton(),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comentarios al envío',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.05),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: TextField(
            controller: _comentariosController,
            maxLines: 4,
            enabled: widget.userRole == 'alumno' && !widget.task.isExpired,
            decoration: InputDecoration(
              hintText: 'Escribe cualquier comentario adicional...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.indigo.shade400,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (widget.userRole == 'alumno' && _currentStatus == TaskStatus.delivered && !widget.task.isExpired)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _eliminarEntrega,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red.shade600,
                side: BorderSide(
                  color: Colors.red.shade300,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.white,
              ),
              child: const Text(
                'ELIMINAR ENTREGA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        if (widget.userRole == 'alumno' && !widget.task.isExpired) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _enviarTarea,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.indigo.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
                shadowColor: Colors.indigo.withOpacity(0.3),
                disabledBackgroundColor: Colors.grey.shade400,
              ),
              child: Text(
                _currentStatus == TaskStatus.delivered ? 'ACTUALIZAR ENTREGA' : 'ENVIAR TAREA',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.indigo.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.indigo.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.indigo.shade600).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor ?? Colors.indigo.shade600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.indigo.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAttachments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.indigo.shade100,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 48,
            color: Colors.indigo.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'No hay archivos adjuntos',
            style: TextStyle(
              color: Colors.indigo.shade400,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega el archivo requerido para tu tarea',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentItem({
    required String filename,
    VoidCallback? onDownload,
    VoidCallback? onRemove,
    String? label,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.05),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.insert_drive_file,
              color: Colors.indigo.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                Text(
                  filename,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.indigo.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onDownload != null)
            IconButton(
              icon: Icon(
                Icons.download,
                size: 20,
                color: Colors.indigo.shade600,
              ),
              onPressed: onDownload,
            ),
          if (onRemove != null)
            IconButton(
              icon: Icon(
                Icons.close,
                size: 20,
                color: Colors.red.shade500,
              ),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }

  Widget _buildAddFileButton() {
    return OutlinedButton(
      onPressed: _agregarArchivo,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.indigo.shade600,
        side: BorderSide(
          color: Colors.indigo.shade300,
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add,
            color: Colors.indigo.shade600,
          ),
          const SizedBox(width: 8),
          Text(
            'Agregar archivo',
            style: TextStyle(
              color: Colors.indigo.shade600,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}