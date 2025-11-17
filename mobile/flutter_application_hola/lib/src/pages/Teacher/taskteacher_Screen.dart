import 'package:flutter/material.dart';
import 'package:flutter_application_hola/src/services/api_task_services.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import 'package:open_file/open_file.dart';

class ProfessionalTaskManagementScreen extends StatefulWidget {
  final int userId;
  final String userRole;
  final ValueNotifier<bool>? navBarVisibilityNotifier;

  const ProfessionalTaskManagementScreen({
    super.key,
    required this.userId,
    required this.userRole,
    this.navBarVisibilityNotifier,
  });

  @override
  State<ProfessionalTaskManagementScreen> createState() => _ProfessionalTaskManagementScreenState();
}

class _ProfessionalTaskManagementScreenState extends State<ProfessionalTaskManagementScreen> with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _manualGradeController = TextEditingController();
  final TextEditingController _announcementTextController = TextEditingController();
  final TextEditingController _announcementTitleController = TextEditingController();
  DateTime? _dueDateTime;
  String _filterStatus = 'Todos';
  final List<String> _statusFilters = ['Todos', 'A tiempo', 'Tarde', 'Sin calificar'];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoadingTasks = true;
  bool _isLoadingAnnouncements = true;
  File? _selectedFile;
  final ApiTaskServices _apiService = ApiTaskServices();
  
  // Controladores de scroll para cada pestaña
  final ScrollController _tab1ScrollController = ScrollController();
  final ScrollController _tab2ScrollController = ScrollController();
  final ScrollController _tab3ScrollController = ScrollController();
  double _lastScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();
    _fetchTasks();
    _fetchAnnouncements();
    
    // Configurar listeners de scroll
    _setupScrollListener(_tab1ScrollController);
    _setupScrollListener(_tab2ScrollController);
    _setupScrollListener(_tab3ScrollController);
  }

  void _setupScrollListener(ScrollController controller) {
    controller.addListener(() {
      if (widget.navBarVisibilityNotifier != null) {
        final currentOffset = controller.offset;
        
        if (currentOffset > _lastScrollOffset + 15 && widget.navBarVisibilityNotifier!.value) {
          // Scroll hacia abajo - ocultar navbar
          widget.navBarVisibilityNotifier!.value = false;
        } else if (currentOffset < _lastScrollOffset - 8 && !widget.navBarVisibilityNotifier!.value && currentOffset > 0) {
          // Scroll hacia arriba - mostrar navbar
          widget.navBarVisibilityNotifier!.value = true;
        } else if (currentOffset <= 0 && !widget.navBarVisibilityNotifier!.value) {
          // Llegamos al top - mostrar navbar
          widget.navBarVisibilityNotifier!.value = true;
        }
        
        _lastScrollOffset = currentOffset;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _commentController.dispose();
    _gradeController.dispose();
    _manualGradeController.dispose();
    _announcementTextController.dispose();
    _announcementTitleController.dispose();
    _animationController.dispose();
    _tab1ScrollController.dispose();
    _tab2ScrollController.dispose();
    _tab3ScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoadingTasks = true);
    try {
      final tasks = await _apiService.displayTasks(
        userId: widget.userId,
        userRole: widget.userRole,
      );
      setState(() {
        _assignments = tasks.map((task) {
          final entregas = (task['deliveries'] as List<dynamic>? ?? []).map((delivery) {
            return {
              'id_entrega': delivery['id_entrega'] ?? delivery['id'],
              'alumno': delivery['alumno'] ?? 'Desconocido',
              'fecha_entrega': delivery['fecha_entrega'] ?? '',
              'calificacion': delivery['calificacion'] ?? null,
              'observaciones': delivery['observaciones'] ?? '',
              'status': delivery['status'] ?? 'pending',
              'archivo_ruta': delivery['archivo_ruta'] ?? 'Sin archivo',
            } as Map<String, dynamic>;
          }).toList();
          return {
            'id': task['id'],
            'titulo': task['title'] ?? task['titulo'] ?? 'Sin título',
            'descripcion': task['description'] ?? task['descripcion'] ?? 'Sin descripción',
            'fecha_entrega': task['due_date'] ?? task['fecha_entrega'] ?? '',
            'hora_cierre': task['due_time'] ?? task['hora_cierre'] ?? '00:00',
            'creador': task['creator'] ?? (task['creador'] != null
                ? '${task['creador']['nombre'] ?? ''} ${task['creador']['apellido'] ?? ''}'.trim()
                : 'Desconocido'),
            'archivo_ruta': task['archivo_ruta'] ?? 'Sin archivo',
            'status': task['status'] ?? 'pending',
            'entregas': entregas,
          } as Map<String, dynamic>;
        }).toList().cast<Map<String, dynamic>>();
        _isLoadingTasks = false;
      });
    } catch (e) {
      setState(() => _isLoadingTasks = false);
      _showSnackBar('Error al cargar tareas: $e', Colors.red[600]);
    }
  }

  Future<void> _fetchAnnouncements() async {
    setState(() => _isLoadingAnnouncements = true);
    try {
      final announcements = await _apiService.getAllAnnouncements();
      setState(() {
        _announcements = announcements.map((announcement) {
          return {
            'id': announcement['id_aviso'],
            'titulo': announcement['titulo'] ?? 'Sin título',
            'texto': announcement['texto'] ?? '',
            'fecha_hora': announcement['fecha_hora'] ?? '',
            'usuario': announcement['usuario'] != null
                ? '${announcement['usuario']['nombre'] ?? ''} ${announcement['usuario']['apellido'] ?? ''}'.trim()
                : 'Desconocido',
          };
        }).toList();
        _isLoadingAnnouncements = false;
      });
    } catch (e) {
      setState(() => _isLoadingAnnouncements = false);
      _showSnackBar('Error al cargar avisos: $e', Colors.red[600]);
    }
  }

  Future<void> _selectDueDateTime(BuildContext context) async {
    final DateTime? dateTime = await showDatePicker(
      context: context,
      initialDate: _dueDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (dateTime != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDateTime ?? DateTime.now()),
      );
      if (time != null) {
        setState(() => _dueDateTime = DateTime(dateTime.year, dateTime.month, dateTime.day, time.hour, time.minute));
      }
    }
  }

  Future<void> _assignTask() async {
    if (_titleController.text.isEmpty || _dueDateTime == null) {
      _showSnackBar('Título y fecha/hora son requeridos', Colors.red[600]);
      return;
    }

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_dueDateTime!);
      final timeStr = DateFormat('HH:mm:ss').format(_dueDateTime!);
      final task = await _apiService.createTask(
        titulo: _titleController.text,
        descripcion: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        fechaEntrega: dateStr,
        horaCierre: timeStr,
        creadoPor: widget.userId,
        archivo: _selectedFile,
      );
      setState(() {
        _assignments.insert(0, {
          'id': int.parse(task['id'].toString()),
          'titulo': task['titulo'] ?? _titleController.text,
          'descripcion': task['descripcion'] ?? 'Sin descripción',
          'fecha_entrega': task['due_date'] ?? task['fecha_entrega'] ?? dateStr,
          'hora_cierre': task['due_time'] ?? task['hora_cierre'] ?? timeStr,
          'creador': task['creador'] != null
              ? '${task['creador']['nombre'] ?? ''} ${task['creador']['apellido'] ?? ''}'.trim()
              : 'Desconocido',
          'archivo_ruta': task['archivo_ruta'] ?? 'Sin archivo',
          'status': task['status'] ?? 'pending',
          'entregas': task['deliveries'] ?? task['entregas'] ?? [],
        });
        _titleController.clear();
        _descriptionController.clear();
        _dueDateTime = null;
        _selectedFile = null;
      });
      _showSnackBar('Tarea asignada correctamente', Colors.green[600]);
    } catch (e) {
      _showSnackBar('Error al asignar tarea: $e', Colors.red[600]);
    }
  }

  Future<void> _editTask(int taskIndex) async {
    final task = _assignments[taskIndex];
    _titleController.text = task['titulo'] ?? '';
    _descriptionController.text = task['descripcion'] ?? '';
    _dueDateTime = task['fecha_entrega'] != null && task['hora_cierre'] != null
        ? DateTime.parse('${task['fecha_entrega']} ${task['hora_cierre'].split(':')[0]}:${task['hora_cierre'].split(':')[1]}:00')
        : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(
          'Editar Tarea',
          style: TextStyle(color: Colors.indigo[900], fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: _inputDecoration('Título de la tarea', Icons.title),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _inputDecoration('Instrucciones de la tarea', Icons.description),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDueDateTime(context),
                child: InputDecorator(
                  decoration: _inputDecoration('Fecha y hora de entrega', Icons.calendar_today),
                  child: Text(
                    _dueDateTime != null
                        ? DateFormat('dd MMM yyyy, HH:mm').format(_dueDateTime!)
                        : 'Seleccionar fecha y hora',
                    style: TextStyle(color: Colors.indigo[900], fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.indigo[600], fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.isEmpty || _dueDateTime == null) {
                _showSnackBar('Título y fecha/hora son requeridos', Colors.red[600]);
                return;
              }
              try {
                final dateStr = DateFormat('yyyy-MM-dd').format(_dueDateTime!);
                final timeStr = DateFormat('HH:mm:ss').format(_dueDateTime!);
                final updatedTask = await _apiService.updateTask(
                  taskId: task['id'],
                  titulo: _titleController.text,
                  descripcion: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
                  fechaEntrega: dateStr,
                  horaCierre: timeStr,
                  archivo: _selectedFile,
                );
                setState(() {
                  _assignments[taskIndex] = {
                    'id': int.parse(updatedTask['id'].toString()),
                    'titulo': updatedTask['titulo'] ?? _titleController.text,
                    'descripcion': updatedTask['descripcion'] ?? 'Sin descripción',
                    'fecha_entrega': updatedTask['due_date'] ?? updatedTask['fecha_entrega'] ?? dateStr,
                    'hora_cierre': updatedTask['due_time'] ?? updatedTask['hora_cierre'] ?? timeStr,
                    'creador': updatedTask['creador'] != null
                        ? '${updatedTask['creador']['nombre'] ?? ''} ${updatedTask['creador']['apellido'] ?? ''}'.trim()
                        : 'Desconocido',
                    'archivo_ruta': updatedTask['archivo_ruta'] ?? 'Sin archivo',
                    'status': updatedTask['status'] ?? 'pending',
                    'entregas': updatedTask['deliveries'] ?? updatedTask['entregas'] ?? [],
                  };
                });
                _titleController.clear();
                _descriptionController.clear();
                _dueDateTime = null;
                _selectedFile = null;
                Navigator.pop(context);
                _showSnackBar('Tarea actualizada correctamente', Colors.green[600]);
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar('Error al actualizar tarea: $e', Colors.red[600]);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Guardar', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(int taskIndex) async {
    final task = _assignments[taskIndex];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(
          'Confirmar Eliminación',
          style: TextStyle(color: Colors.indigo[900], fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar la tarea "${task['titulo']}"?',
          style: TextStyle(color: Colors.indigo[900], fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: TextStyle(color: Colors.indigo[600], fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sí', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _apiService.deleteTask(task['id']);
        setState(() {
          _assignments.removeAt(taskIndex);
        });
        _showSnackBar('Tarea eliminada correctamente', Colors.green[600]);
      } catch (e) {
        _showSnackBar('Error al eliminar tarea: $e', Colors.red[600]);
      }
    }
  }

  Future<void> _createAnnouncement() async {
    if (_announcementTitleController.text.isEmpty || _announcementTextController.text.isEmpty) {
      _showSnackBar('Título y texto del aviso son requeridos', Colors.red[600]);
      return;
    }
    try {
      final announcement = await _apiService.createAnnouncement(
        idUsuario: widget.userId,
        titulo: _announcementTitleController.text,
        texto: _announcementTextController.text,
      );
      setState(() {
        _announcements.insert(0, {
          'id': announcement['id_aviso'],
          'titulo': announcement['titulo'] ?? 'Sin título',
          'texto': announcement['texto'] ?? '',
          'fecha_hora': announcement['fecha_hora'] ?? '',
          'usuario': announcement['usuario'] != null
              ? '${announcement['usuario']['nombre'] ?? ''} ${announcement['usuario']['apellido'] ?? ''}'.trim()
              : 'Desconocido',
        });
        _announcementTitleController.clear();
        _announcementTextController.clear();
      });
      _showSnackBar('Aviso creado correctamente', Colors.green[600]);
    } catch (e) {
      _showSnackBar('Error al crear aviso: $e', Colors.red[600]);
    }
  }

  Future<void> _editAnnouncement(int announcementIndex) async {
    final announcement = _announcements[announcementIndex];
    _announcementTitleController.text = announcement['titulo'] ?? '';
    _announcementTextController.text = announcement['texto'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(
          'Editar Aviso',
          style: TextStyle(color: Colors.indigo[900], fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _announcementTitleController,
                decoration: _inputDecoration('Título del aviso', Icons.title),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _announcementTextController,
                maxLines: 4,
                decoration: _inputDecoration('Texto del aviso', Icons.announcement),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.indigo[600], fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_announcementTitleController.text.isEmpty || _announcementTextController.text.isEmpty) {
                _showSnackBar('Título y texto del aviso son requeridos', Colors.red[600]);
                return;
              }
              try {
                final updatedAnnouncement = await _apiService.updateAnnouncement(
                  announcementId: announcement['id'],
                  idUsuario: widget.userId,
                  titulo: _announcementTitleController.text,
                  texto: _announcementTextController.text,
                );
                setState(() {
                  _announcements[announcementIndex] = {
                    'id': updatedAnnouncement['id_aviso'],
                    'titulo': updatedAnnouncement['titulo'] ?? '',
                    'texto': updatedAnnouncement['texto'] ?? '',
                    'fecha_hora': updatedAnnouncement['fecha_hora'] ?? '',
                    'usuario': updatedAnnouncement['usuario'] != null
                        ? '${updatedAnnouncement['usuario']['nombre'] ?? ''} ${updatedAnnouncement['usuario']['apellido'] ?? ''}'.trim()
                        : 'Desconocido',
                  };
                });
                _announcementTitleController.clear();
                _announcementTextController.clear();
                Navigator.pop(context);
                _showSnackBar('Aviso actualizado correctamente', Colors.green[600]);
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar('Error al actualizar aviso: $e', Colors.red[600]);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Guardar', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAnnouncement(int announcementIndex) async {
    final announcement = _announcements[announcementIndex];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(
          'Confirmar Eliminación',
          style: TextStyle(color: Colors.indigo[900], fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar el aviso "${announcement['titulo']}"?',
          style: TextStyle(color: Colors.indigo[900], fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: TextStyle(color: Colors.indigo[600], fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sí', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _apiService.deleteAnnouncement(announcement['id']);
        setState(() {
          _announcements.removeAt(announcementIndex);
        });
        _showSnackBar('Aviso eliminado correctamente', Colors.green[600]);
      } catch (e) {
        _showSnackBar('Error al eliminar aviso: $e', Colors.red[600]);
      }
    }
  }

  Future<void> _gradeAssignment(int assignmentIndex, int submissionIndex) async {
    final submission = Map<String, dynamic>.from(_assignments[assignmentIndex]['entregas'][submissionIndex]);
    _manualGradeController.text = (submission['calificacion'] is num)
        ? submission['calificacion'].toStringAsFixed(0)
        : (submission['calificacion'] != null ? submission['calificacion'].toString() : '');
    _commentController.text = submission['observaciones']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(
          'Calificar a ${submission['alumno'] ?? 'Estudiante'}',
          style: TextStyle(color: Colors.indigo[900], fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _manualGradeController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Calificación (0-100)', Icons.grade),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: _inputDecoration('Comentario', Icons.comment),
              ),
              const SizedBox(height: 16),
              if (submission['archivo_ruta'] != null && submission['archivo_ruta'] != 'Sin archivo') ...[
                Text(
                  'Archivo adjunto:',
                  style: TextStyle(color: Colors.indigo[700], fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _downloadFile('entrega', submission['id_entrega'], submission['archivo_ruta']),
                  icon: Icon(Icons.download, color: Colors.indigo[600]),
                  label: Text('Descargar archivo', style: TextStyle(color: Colors.indigo[600])),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.indigo[600]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.indigo[600], fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              final grade = double.tryParse(_manualGradeController.text) ?? 0.0;
              if (grade < 0 || grade > 100) {
                _showSnackBar('La calificación debe estar entre 0 y 100', Colors.red[600]);
                return;
              }
              try {
                final updatedDelivery = await _apiService.updateDelivery(
                  deliveryId: submission['id_entrega'],
                  calificacion: grade,
                  observaciones: _commentController.text.isNotEmpty ? _commentController.text : null,
                );
                setState(() {
                  final updatedSubmission = Map<String, dynamic>.from(submission)
                    ..['calificacion'] = updatedDelivery['calificacion'] ?? grade
                    ..['observaciones'] = updatedDelivery['observaciones'] ?? _commentController.text
                    ..['status'] = updatedDelivery['status'] ?? submission['status'];
                  _assignments[assignmentIndex]['entregas'][submissionIndex] = updatedSubmission;
                });
                _commentController.clear();
                _manualGradeController.clear();
                Navigator.pop(context);
                _showSnackBar('Calificación guardada para ${submission['alumno']}', Colors.green[600]);
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar('Error al guardar calificación: $e', Colors.red[600]);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Guardar', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );
  }

Future<void> _downloadFile(String resourceType, int resourceId, String fileUrl) async {
  if (fileUrl == 'Sin archivo' || fileUrl.isEmpty) {
    _showSnackBar('No hay archivo disponible para descargar', Colors.red[600]);
    return;
  }

  try {
    final fileName = fileUrl.split('/').last;
    _showSnackBar('Descargando archivo...', Colors.blue[600]);

    final file = await _apiService.downloadFile(
      resourceType: resourceType,
      resourceId: resourceId,
      fileName: fileName,
    );

    if (await file.exists() && (await file.length() > 0)) {
      // Mostrar diálogo para abrir el archivo
      final shouldOpen = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Descarga completada'),
          content: Text('El archivo $fileName se ha descargado correctamente. ¿Deseas abrirlo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Sí'),
            ),
          ],
        ),
      );

      if (shouldOpen == true) {
        // Abrir el archivo con un visor apropiado
        await OpenFile.open(file.path).catchError((error) {
          _showSnackBar('No se pudo abrir el archivo: $error', Colors.red[600]);
        });
      }
    } else {
      _showSnackBar('El archivo descargado está vacío o no existe', Colors.red[600]);
    }
  } catch (e) {
    _showSnackBar('Error al descargar archivo: $e', Colors.red[600]);
  }
}



  void _showTaskDetails(int taskIndex) {
    final task = _assignments[taskIndex];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(
          task['titulo'] ?? task['title'] ?? 'Sin título',
          style: TextStyle(color: Colors.indigo[900], fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Descripción:', style: TextStyle(color: Colors.indigo[700], fontSize: 16, fontWeight: FontWeight.w600)),
              Text(task['description'] ?? task['descripcion'] ?? 'Sin descripción', style: TextStyle(color: Colors.indigo[900])),
              const SizedBox(height: 8),
              Text('Fecha de cierre:', style: TextStyle(color: Colors.indigo[700], fontSize: 16, fontWeight: FontWeight.w600)),
              Text('${_formatDateTime(task['fecha_entrega'], null)} ${task['hora_cierre']}', style: TextStyle(color: Colors.indigo[900])),
              const SizedBox(height: 8),
              Text('Creador:', style: TextStyle(color: Colors.indigo[700], fontSize: 16, fontWeight: FontWeight.w600)),
              Text(task['creator'] ?? task['creador'] ?? 'Desconocido', style: TextStyle(color: Colors.indigo[900])),
              if (task['archivo_ruta'] != null && task['archivo_ruta'] != 'Sin archivo') ...[
                const SizedBox(height: 8),
                Text('Archivo adjunto:', style: TextStyle(color: Colors.indigo[700], fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _downloadFile('tarea', task['id'], task['archivo_ruta']),
                  icon: Icon(Icons.download, color: Colors.indigo[600]),
                  label: Text('Descargar archivo', style: TextStyle(color: Colors.indigo[600])),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.indigo[600]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: TextStyle(color: Colors.indigo[600], fontSize: 16)),
          ),
        ],
      ),
    );
  }
  

  void _showSnackBar(String message, Color? backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      prefixIcon: Icon(icon, color: Colors.indigo[600]),
      filled: true,
      fillColor: Colors.indigo[50],
      labelStyle: TextStyle(color: Colors.indigo[700]),
    );
  }

  Color _getStatusColor(String? status) {
    return status == 'onTime' ? Colors.green[600]! : (status == 'late' ? Colors.orange[600]! : Colors.grey[400]!);
  }

  Color _getGradeColor(dynamic grade) {
    if (grade == null || grade == '') return Colors.grey[400]!;
    final doubleGrade = double.tryParse(grade.toString()) ?? 0.0;
    if (doubleGrade >= 90) return Colors.green[600]!;
    if (doubleGrade >= 70) return Colors.blue[600]!;
    if (doubleGrade >= 50) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  String _formatDateTime(String? dateTimeStr, String? timeStr) {
    if (dateTimeStr == null) return 'Sin fecha';
    try {
      DateTime dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  List<Map<String, dynamic>> _filteredSubmissions(List<dynamic> submissions) {
    final now = DateTime.now();
    return submissions.where((submission) {
      final deliveryDate = submission['fecha_entrega'] != null ? DateTime.parse(submission['fecha_entrega']) : now;
      final taskDeadline = _assignments.firstWhere((task) => task['entregas'].contains(submission))['fecha_entrega'] != null
          ? DateTime.parse('${_assignments.firstWhere((task) => task['entregas'].contains(submission))['fecha_entrega']} ${_assignments.firstWhere((task) => task['entregas'].contains(submission))['hora_cierre']}')
          : now;
      if (_filterStatus == 'Todos') return true;
      if (_filterStatus == 'A tiempo') return deliveryDate.isBefore(taskDeadline) || deliveryDate.isAtSameMomentAs(taskDeadline);
      if (_filterStatus == 'Tarde') return deliveryDate.isAfter(taskDeadline);
      if (_filterStatus == 'Sin calificar') return submission['calificacion'] == null || submission['calificacion'] == '';
      return true;
    }).cast<Map<String, dynamic>>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: FadeTransition(
            opacity: _fadeAnimation,
            child: const Text(
              'Gestión de Tareas',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.indigo[800],
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[800]!, Colors.indigo[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Asignar Tarea', icon: Icon(Icons.assignment_add)),
              Tab(text: 'Ver Entregas', icon: Icon(Icons.list_alt)),
              Tab(text: 'Publicaciones', icon: Icon(Icons.announcement)),
            ],
            onTap: (index) => setState(() => _currentTab = index),
          ),
        ),
        body: TabBarView(
          children: [
            // Pestaña 1: Asignar Tareas
            NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (scrollNotification is ScrollUpdateNotification && widget.navBarVisibilityNotifier != null) {
                  final currentOffset = scrollNotification.metrics.pixels;
                  
                  if (currentOffset > _lastScrollOffset + 15 && widget.navBarVisibilityNotifier!.value) {
                    // Scroll hacia abajo - ocultar navbar
                    widget.navBarVisibilityNotifier!.value = false;
                  } else if (currentOffset < _lastScrollOffset - 8 && !widget.navBarVisibilityNotifier!.value && currentOffset > 0) {
                    // Scroll hacia arriba - mostrar navbar
                    widget.navBarVisibilityNotifier!.value = true;
                  } else if (currentOffset <= 0 && !widget.navBarVisibilityNotifier!.value) {
                    // Llegamos al top - mostrar navbar
                    widget.navBarVisibilityNotifier!.value = true;
                  }
                  
                  _lastScrollOffset = currentOffset;
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: _tab1ScrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SlideTransition(
                      position: _slideAnimation,
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                'Nueva Tarea',
                                style: TextStyle(color: Colors.indigo[900], fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _titleController,
                                decoration: _inputDecoration('Título de la tarea', Icons.title),
                                onChanged: (value) => setState(() {}),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _descriptionController,
                                maxLines: 4,
                                decoration: _inputDecoration('Instrucciones de la tarea', Icons.description),
                              ),
                              const SizedBox(height: 16),
                              InkWell(
                                onTap: () => _selectDueDateTime(context),
                                child: InputDecorator(
                                  decoration: _inputDecoration('Fecha y hora de entrega', Icons.calendar_today),
                                  child: Text(
                                    _dueDateTime != null
                                        ? DateFormat('dd MMM yyyy, HH:mm').format(_dueDateTime!)
                                        : 'Seleccionar fecha y hora',
                                    style: TextStyle(color: Colors.indigo[900], fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Subir archivo PDF (opcional)',
                                style: TextStyle(color: Colors.indigo[700], fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  // Lógica para subir archivo PDF
                                },
                                icon: Icon(Icons.upload, color: Colors.indigo[600]),
                                label: Text(
                                  _selectedFile == null ? 'Seleccionar archivo' : 'Archivo seleccionado',
                                  style: TextStyle(color: Colors.indigo[600]),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.indigo[600]!),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _assignTask,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo[600],
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: const Text(
                                    'Asignar Tarea',
                                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tareas Asignadas',
                      style: TextStyle(color: Colors.indigo[900], fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _isLoadingTasks
                        ? const Center(child: CircularProgressIndicator())
                        : _assignments.isEmpty
                            ? Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.assignment_outlined, size: 60, color: Colors.indigo[300]),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No hay tareas asignadas',
                                      style: TextStyle(fontSize: 18, color: Colors.indigo[600], fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _assignments.length,
                                itemBuilder: (context, index) {
                                  final task = _assignments[index];
                                  return FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: Card(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      color: Colors.white,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.indigo[100],
                                          child: Icon(Icons.assignment, color: Colors.indigo[600], size: 24),
                                        ),
                                        title: Text(
                                          task['titulo'] ?? 'Sin título',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo[900]),
                                        ),
                                        subtitle: Text(
                                          'Entrega: ${_formatDateTime(task['fecha_entrega'], null)} ${task['hora_cierre']}',
                                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.visibility, color: Colors.indigo[600]),
                                              onPressed: () => _showTaskDetails(index),
                                              tooltip: 'Ver detalles',
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.edit, color: Colors.indigo[600]),
                                              onPressed: () => _editTask(index),
                                              tooltip: 'Editar tarea',
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete, color: Colors.red[600]),
                                              onPressed: () => _deleteTask(index),
                                              tooltip: 'Eliminar tarea',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ],
                ),
              ),
            ),

            // Pestaña 2: Ver Entregas
            _isLoadingTasks
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
                    onNotification: (scrollNotification) {
                      if (scrollNotification is ScrollUpdateNotification && widget.navBarVisibilityNotifier != null) {
                        final currentOffset = scrollNotification.metrics.pixels;
                        
                        if (currentOffset > _lastScrollOffset + 15 && widget.navBarVisibilityNotifier!.value) {
                          // Scroll hacia abajo - ocultar navbar
                          widget.navBarVisibilityNotifier!.value = false;
                        } else if (currentOffset < _lastScrollOffset - 8 && !widget.navBarVisibilityNotifier!.value && currentOffset > 0) {
                          // Scroll hacia arriba - mostrar navbar
                          widget.navBarVisibilityNotifier!.value = true;
                        } else if (currentOffset <= 0 && !widget.navBarVisibilityNotifier!.value) {
                          // Llegamos al top - mostrar navbar
                          widget.navBarVisibilityNotifier!.value = true;
                        }
                        
                        _lastScrollOffset = currentOffset;
                      }
                      return false;
                    },
                    child: CustomScrollView(
                      controller: _tab2ScrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: DropdownButton<String>(
                              value: _filterStatus,
                              isExpanded: true,
                              items: _statusFilters.map((String status) {
                                return DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status, style: TextStyle(color: Colors.indigo[900], fontSize: 16)),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() => _filterStatus = newValue!);
                              },
                              underline: Container(height: 1, color: Colors.indigo[200]),
                              icon: Icon(Icons.filter_list, color: Colors.indigo[600]),
                              style: TextStyle(color: Colors.indigo[900], fontSize: 16),
                              dropdownColor: Colors.white,
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, assignmentIndex) {
                              if (_assignments.isEmpty) {
                                return Container(
                                  height: MediaQuery.of(context).size.height - 200,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.assignment_outlined, size: 60, color: Colors.indigo[300]),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No hay tareas asignadas',
                                        style: TextStyle(fontSize: 18, color: Colors.indigo[600], fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final assignment = _assignments[assignmentIndex];
                              final filteredSubmissions = _filteredSubmissions(assignment['entregas'] ?? []);
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  color: Colors.white,
                                  child: ExpansionTile(
                                    backgroundColor: Colors.white,
                                    collapsedBackgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.indigo[100],
                                      child: Icon(Icons.assignment, color: Colors.indigo[600], size: 24),
                                    ),
                                    title: Text(
                                      assignment['titulo'] ?? 'Sin título',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
                                    ),
                                    subtitle: Text(
                                      'Entrega: ${_formatDateTime(assignment['fecha_entrega'], null)} ${assignment['hora_cierre']}',
                                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo[600]!.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${filteredSubmissions.length}',
                                        style: TextStyle(color: Colors.indigo[600], fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    children: [
                                      if (filteredSubmissions.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.info_outline, color: Colors.grey[400]),
                                              const SizedBox(width: 8),
                                              Text(
                                                'No hay entregas aún',
                                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        ...filteredSubmissions.map((submission) {
                                          final submissionIndex = (assignment['entregas'] ?? []).indexOf(submission);
                                          final isOnTime = submission['status'] == 'onTime';
                                          return SlideTransition(
                                            position: _slideAnimation,
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: isOnTime ? Colors.green[50] : Colors.orange[50],
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isOnTime ? Colors.green[200]! : Colors.orange[200]!,
                                                  width: 1,
                                                ),
                                              ),
                                              child: ListTile(
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                title: Text(
                                                  submission['alumno'] ?? 'Desconocido',
                                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo[900]),
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Entregado: ${_formatDateTime(submission['fecha_entrega'], null)}',
                                                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: _getStatusColor(submission['status']).withOpacity(0.2),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Text(
                                                            isOnTime ? 'A tiempo' : 'Tarde',
                                                            style: TextStyle(
                                                              color: _getStatusColor(submission['status']),
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                        if (submission['calificacion'] != null && submission['calificacion'] != '') ...[
                                                          const SizedBox(width: 8),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: _getGradeColor(submission['calificacion']),
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            child: Text(
                                                              (double.tryParse(submission['calificacion'].toString()) ?? 0.0).toStringAsFixed(0),
                                                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                    if (submission['observaciones'] != null && submission['observaciones'].isNotEmpty) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        '"${submission['observaciones']}"',
                                                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[600], fontSize: 14),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(
                                                        (submission['calificacion'] == null || submission['calificacion'] == '')
                                                            ? Icons.grading
                                                            : Icons.edit,
                                                        color: Colors.indigo[600],
                                                        size: 24,
                                                      ),
                                                      onPressed: () => _gradeAssignment(assignmentIndex, submissionIndex),
                                                      tooltip: (submission['calificacion'] == null || submission['calificacion'] == '')
                                                          ? 'Calificar'
                                                          : 'Editar calificación',
                                                    ),
                                                    if (submission['archivo_ruta'] != null && submission['archivo_ruta'] != 'Sin archivo')
                                                      IconButton(
                                                        icon: Icon(Icons.download, color: Colors.blue[600], size: 24),
                                                        onPressed: () => _downloadFile('entrega', submission['id_entrega'], submission['archivo_ruta']),
                                                        tooltip: 'Descargar entrega',
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: _assignments.isEmpty ? 1 : _assignments.length,
                          ),
                        ),
                      ],
                    ),
                  ),

            // Pestaña 3: Publicaciones
            _isLoadingAnnouncements
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
                    onNotification: (scrollNotification) {
                      if (scrollNotification is ScrollUpdateNotification && widget.navBarVisibilityNotifier != null) {
                        final currentOffset = scrollNotification.metrics.pixels;
                        
                        if (currentOffset > _lastScrollOffset + 15 && widget.navBarVisibilityNotifier!.value) {
                          // Scroll hacia abajo - ocultar navbar
                          widget.navBarVisibilityNotifier!.value = false;
                        } else if (currentOffset < _lastScrollOffset - 8 && !widget.navBarVisibilityNotifier!.value && currentOffset > 0) {
                          // Scroll hacia arriba - mostrar navbar
                          widget.navBarVisibilityNotifier!.value = true;
                        } else if (currentOffset <= 0 && !widget.navBarVisibilityNotifier!.value) {
                          // Llegamos al top - mostrar navbar
                          widget.navBarVisibilityNotifier!.value = true;
                        }
                        
                        _lastScrollOffset = currentOffset;
                      }
                      return false;
                    },
                    child: SingleChildScrollView(
                      controller: _tab3ScrollController,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SlideTransition(
                            position: _slideAnimation,
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Text(
                                      'Nuevo Aviso',
                                      style: TextStyle(color: Colors.indigo[900], fontSize: 22, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 20),
                                    TextField(
                                      controller: _announcementTitleController,
                                      decoration: _inputDecoration('Título del aviso', Icons.title),
                                      onChanged: (value) => setState(() {}),
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _announcementTextController,
                                      maxLines: 4,
                                      decoration: _inputDecoration('Texto del aviso', Icons.announcement),
                                      onChanged: (value) => setState(() {}),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: _createAnnouncement,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.indigo[600],
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                        child: const Text(
                                          'Publicar Aviso',
                                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Avisos Publicados',
                            style: TextStyle(color: Colors.indigo[900], fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          if (_announcements.isEmpty)
                            Container(
                              height: MediaQuery.of(context).size.height - 300,
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.announcement_outlined, size: 60, color: Colors.indigo[300]),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No hay avisos publicados',
                                    style: TextStyle(fontSize: 18, color: Colors.indigo[600], fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._announcements.asMap().entries.map((entry) {
                              final index = entry.key;
                              final announcement = entry.value;
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  color: Colors.white,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.indigo[100],
                                      child: Icon(Icons.announcement, color: Colors.indigo[600], size: 24),
                                    ),
                                    title: Text(
                                      announcement['titulo'] ?? 'Sin título',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo[900]),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          announcement['texto'] ?? '',
                                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Publicado por: ${announcement['usuario'] ?? 'Desconocido'}',
                                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                        ),
                                        Text(
                                          'Fecha: ${_formatDateTime(announcement['fecha_hora'], null)}',
                                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit, color: Colors.indigo[600], size: 24),
                                          onPressed: () => _editAnnouncement(index),
                                          tooltip: 'Editar aviso',
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red[600], size: 24),
                                          onPressed: () => _deleteAnnouncement(index),
                                          tooltip: 'Eliminar aviso',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}