import 'package:flutter/material.dart';
import 'package:flutter_application_hola/src/services/api_task_services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';

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
    
    _setupScrollListener(_tab1ScrollController);
    _setupScrollListener(_tab2ScrollController);
    _setupScrollListener(_tab3ScrollController);
  }

  void _setupScrollListener(ScrollController controller) {
    controller.addListener(() {
      if (widget.navBarVisibilityNotifier == null) return;
      
      final currentOffset = controller.offset;
      if (currentOffset > _lastScrollOffset + 15 && widget.navBarVisibilityNotifier!.value) {
        widget.navBarVisibilityNotifier!.value = false;
      } else if (currentOffset < _lastScrollOffset - 8 && !widget.navBarVisibilityNotifier!.value && currentOffset > 0) {
        widget.navBarVisibilityNotifier!.value = true;
      } else if (currentOffset <= 0 && !widget.navBarVisibilityNotifier!.value) {
        widget.navBarVisibilityNotifier!.value = true;
      }
      _lastScrollOffset = currentOffset;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _commentController.dispose();
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
      print('Tareas obtenidas del API: ${tasks.length}');
     
      if (mounted) {
        setState(() {
          _assignments = tasks;
          _isLoadingTasks = false;
          _printDebugInfo();
        });
      }
    } catch (e) {
      print('Error al cargar tareas: $e');
      if (mounted) {
        setState(() => _isLoadingTasks = false);
        _showSnackBar('Error al cargar tareas. Verifica tu conexión o intenta más tarde.', Colors.red[700]);
      }
    }
  }

  Future<void> _fetchAnnouncements() async {
    setState(() => _isLoadingAnnouncements = true);
    try {
      final announcements = await _apiService.getAllAnnouncements();
     
      print('Avisos obtenidos del API: $announcements');
     
      if (mounted) {
        setState(() {
          _announcements = announcements.map((announcement) {
            final id = announcement['id_aviso'] ?? announcement['id'] ?? 0;
            final titulo = announcement['titulo'] ?? announcement['title'] ?? 'Sin título';
            final texto = announcement['texto'] ?? announcement['content'] ?? '';
            final fechaHora = announcement['fecha_hora'] ?? announcement['fecha'] ?? announcement['created_at'] ?? '';
           
            String usuario = 'Desconocido';
            if (announcement['usuario'] != null && announcement['usuario'] is Map) {
              usuario = '${announcement['usuario']['nombre'] ?? ''} ${announcement['usuario']['apellido'] ?? ''}'.trim();
            } else if (announcement['creador'] != null && announcement['creador'] is Map) {
              usuario = '${announcement['creador']['nombre'] ?? ''} ${announcement['creador']['apellido'] ?? ''}'.trim();
            } else if (announcement['user'] != null && announcement['user'] is Map) {
              usuario = '${announcement['user']['name'] ?? ''} ${announcement['user']['last_name'] ?? ''}'.trim();
            }
           
            return {
              'id': id,
              'titulo': titulo,
              'texto': texto,
              'fecha_hora': fechaHora,
              'usuario': usuario.isNotEmpty ? usuario : 'Desconocido',
            };
          }).toList();
         
          _isLoadingAnnouncements = false;
        });
      }
    } catch (e) {
      print('Error al cargar avisos: $e');
      if (mounted) {
        setState(() => _isLoadingAnnouncements = false);
        _showSnackBar('Error al cargar avisos', Colors.red[700]);
      }
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

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
      );
      
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
        _showSnackBar('Archivo seleccionado: ${result.files.single.name}', Colors.green[600]);
      }
    } catch (e) {
      print('Error al seleccionar archivo: $e');
      _showSnackBar('Error al seleccionar archivo', Colors.red[600]);
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
     
      print('Creando tarea con datos:');
      print(' Título: ${_titleController.text}');
      print(' Fecha: $dateStr');
      print(' Hora: $timeStr');
      print(' Creado por: ${widget.userId}');
      print(' Archivo: ${_selectedFile?.path}');
     
      final task = await _apiService.createTask(
        titulo: _titleController.text,
        descripcion: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        fechaEntrega: dateStr,
        horaCierre: timeStr,
        creadoPor: widget.userId,
        archivo: _selectedFile,
      );
     
      print('Tarea creada: $task');
     
      setState(() {
        _assignments.insert(0, {
          'id': int.parse(task['id']?.toString() ?? '0'),
          'title': task['titulo'] ?? _titleController.text,
          'description': task['descripcion'] ?? 'Sin descripción',
          'due_date': dateStr,
          'due_time': timeStr,
          'creator': 'Tú',
          'creator_id': widget.userId,
          'archivo_ruta': task['archivo_ruta'] ?? 'Sin archivo',
          'status': 'pending',
          'deliveries': [],
        });
       
        _titleController.clear();
        _descriptionController.clear();
        _dueDateTime = null;
        _selectedFile = null;
      });
     
      _showSnackBar('✅ Tarea asignada correctamente', Colors.green[600]);
      await _fetchTasks();
     
    } catch (e) {
      print('Error al asignar tarea: $e');
      _showSnackBar('❌ Error al asignar tarea: ${e.toString()}', Colors.red[600]);
    }
  }

  Future<void> _editTask(int taskIndex) async {
    if (taskIndex >= _assignments.length) return;
   
    final task = _assignments[taskIndex];
    _titleController.text = task['title'] ?? '';
    _descriptionController.text = task['description'] ?? '';
   
    try {
      if (task['due_date'] != null) {
        final dateStr = task['due_date'].toString();
        final timeStr = task['due_time']?.toString() ?? '23:59:00';
        _dueDateTime = DateTime.parse('$dateStr ${timeStr.split(':')[0]}:${timeStr.split(':')[1]}:00');
      }
    } catch (e) {
      print('Error parseando fecha: $e');
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text('Editar Tarea', style: TextStyle(color: Colors.indigo[900], fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _titleController, decoration: _inputDecoration('Título de la tarea', Icons.title)),
              const SizedBox(height: 16),
              TextField(controller: _descriptionController, maxLines: 4, decoration: _inputDecoration('Instrucciones de la tarea', Icons.description)),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDueDateTime(context),
                child: InputDecorator(
                  decoration: _inputDecoration('Fecha y hora de entrega', Icons.calendar_today),
                  child: Text(
                    _dueDateTime != null ? DateFormat('dd MMM yyyy, HH:mm').format(_dueDateTime!) : 'Seleccionar fecha y hora',
                    style: TextStyle(color: Colors.indigo[900], fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedFile != null)
                Text(
                  'Archivo seleccionado: ${_selectedFile!.path.split('/').last}',
                  style: TextStyle(color: Colors.indigo[600]),
                ),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: Icon(Icons.upload, color: Colors.indigo[600]),
                label: const Text('Cambiar archivo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.indigo[600])),
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
               
                print('Tarea actualizada: $updatedTask');
               
                setState(() {
                  _assignments[taskIndex] = {
                    'id': int.parse(updatedTask['id']?.toString() ?? '0'),
                    'title': updatedTask['titulo'] ?? _titleController.text,
                    'description': updatedTask['descripcion'] ?? 'Sin descripción',
                    'due_date': dateStr,
                    'due_time': timeStr,
                    'creator': 'Tú',
                    'creator_id': widget.userId,
                    'archivo_ruta': updatedTask['archivo_ruta'] ?? task['archivo_ruta'] ?? 'Sin archivo',
                    'status': task['status'] ?? 'pending',
                    'deliveries': task['deliveries'] ?? [],
                  };
                });
               
                _titleController.clear();
                _descriptionController.clear();
                _dueDateTime = null;
                _selectedFile = null;
               
                Navigator.pop(context);
                _showSnackBar('✅ Tarea actualizada correctamente', Colors.green[600]);
                await _fetchTasks();
               
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar('❌ Error al actualizar tarea: ${e.toString()}', Colors.red[600]);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[600]),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTask(int taskIndex) async {
    if (taskIndex >= _assignments.length) return;
   
    final task = _assignments[taskIndex];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text('Confirmar Eliminación', style: TextStyle(color: Colors.indigo[900], fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de que deseas eliminar la tarea "${task['title']}"?', style: TextStyle(color: Colors.indigo[900])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: TextStyle(color: Colors.indigo[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
            child: const Text('Sí', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
   
    if (confirm == true) {
      try {
        await _apiService.deleteTask(task['id']);
        setState(() => _assignments.removeAt(taskIndex));
        _showSnackBar('✅ Tarea eliminada correctamente', Colors.green[600]);
      } catch (e) {
        print('Error al eliminar tarea: $e');
        _showSnackBar('❌ Error al eliminar tarea: ${e.toString()}', Colors.red[600]);
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
     
      print('Aviso creado: $announcement');
     
      setState(() {
        _announcements.insert(0, {
          'id': announcement['id_aviso'] ?? announcement['id'] ?? 0,
          'titulo': announcement['titulo'] ?? _announcementTitleController.text,
          'texto': announcement['texto'] ?? _announcementTextController.text,
          'fecha_hora': announcement['fecha_hora'] ?? announcement['created_at'] ?? DateTime.now().toString(),
          'usuario': 'Tú',
        });
        _announcementTitleController.clear();
        _announcementTextController.clear();
      });
     
      _showSnackBar('✅ Aviso creado correctamente', Colors.green[600]);
      await _fetchAnnouncements();
     
    } catch (e) {
      print('Error al crear aviso: $e');
      _showSnackBar('❌ Error al crear aviso: ${e.toString()}', Colors.red[600]);
    }
  }

  Future<void> _editAnnouncement(int announcementIndex) async {
    if (announcementIndex >= _announcements.length) return;
   
    final announcement = _announcements[announcementIndex];
    _announcementTitleController.text = announcement['titulo'] ?? '';
    _announcementTextController.text = announcement['texto'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text('Editar Aviso', style: TextStyle(color: Colors.indigo[900], fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _announcementTitleController, decoration: _inputDecoration('Título del aviso', Icons.title)),
              const SizedBox(height: 16),
              TextField(controller: _announcementTextController, maxLines: 4, decoration: _inputDecoration('Texto del aviso', Icons.announcement)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: Colors.indigo[600])),
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
               
                print('Aviso actualizada: $updatedAnnouncement');
               
                setState(() {
                  _announcements[announcementIndex] = {
                    'id': updatedAnnouncement['id_aviso'] ?? updatedAnnouncement['id'] ?? 0,
                    'titulo': updatedAnnouncement['titulo'] ?? _announcementTitleController.text,
                    'texto': updatedAnnouncement['texto'] ?? _announcementTextController.text,
                    'fecha_hora': updatedAnnouncement['fecha_hora'] ?? updatedAnnouncement['created_at'] ?? DateTime.now().toString(),
                    'usuario': 'Tú',
                  };
                });
               
                _announcementTitleController.clear();
                _announcementTextController.clear();
                Navigator.pop(context);
                _showSnackBar('✅ Aviso actualizado correctamente', Colors.green[600]);
                await _fetchAnnouncements();
               
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar('❌ Error al actualizar aviso: ${e.toString()}', Colors.red[600]);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[600]),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAnnouncement(int announcementIndex) async {
    if (announcementIndex >= _announcements.length) return;
   
    final announcement = _announcements[announcementIndex];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text('Confirmar Eliminación', style: TextStyle(color: Colors.indigo[900], fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de que deseas eliminar el aviso "${announcement['titulo']}"?', style: TextStyle(color: Colors.indigo[900])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: TextStyle(color: Colors.indigo[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600]),
            child: const Text('Sí', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
   
    if (confirm == true) {
      try {
        await _apiService.deleteAnnouncement(announcement['id']);
        setState(() => _announcements.removeAt(announcementIndex));
        _showSnackBar('✅ Aviso eliminado correctamente', Colors.green[600]);
      } catch (e) {
        print('Error al eliminar aviso: $e');
        _showSnackBar('❌ Error al eliminar aviso: ${e.toString()}', Colors.red[600]);
      }
    }
  }

  Future<void> _gradeAssignment(int assignmentIndex, int submissionIndex) async {
    try {
      if (assignmentIndex >= _assignments.length) {
        _showSnackBar('Error: Tarea no encontrada', Colors.red[600]);
        return;
      }
     
      final assignment = _assignments[assignmentIndex];
      final entregas = assignment['deliveries'] as List<dynamic>? ?? [];
     
      if (submissionIndex >= entregas.length) {
        _showSnackBar('Error: Entrega no encontrada', Colors.red[600]);
        return;
      }
     
      final submission = Map<String, dynamic>.from(entregas[submissionIndex]);
      print('Calificando entrega: $submission');
     
      // Manejar la calificación
      dynamic calificacionActual = submission['calificacion'];
      _manualGradeController.text = '0';
     
      if (calificacionActual != null) {
        if (calificacionActual is num) {
          _manualGradeController.text = calificacionActual.toStringAsFixed(0);
        } else if (calificacionActual.toString().isNotEmpty &&
                   calificacionActual.toString().toLowerCase() != 'null' &&
                   calificacionActual != 'Sin calificar') {
          _manualGradeController.text = calificacionActual.toString();
        }
      }
     
      _commentController.text = submission['observaciones']?.toString() ?? '';
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: Text(
            'Calificar a ${submission['alumno'] ?? 'Estudiante'}',
            style: TextStyle(color: Colors.indigo[900], fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tarea: ${assignment['title'] ?? 'Sin título'}',
                  style: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estudiante: ${submission['alumno'] ?? 'Desconocido'}',
                  style: TextStyle(color: Colors.indigo[600]),
                ),
                const SizedBox(height: 16),
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
                if (submission['archivo_ruta'] != null &&
                    submission['archivo_ruta'].toString().isNotEmpty &&
                    submission['archivo_ruta'] != 'Sin archivo') ...[
                  Text(
                    'Archivo adjunto:',
                    style: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _openOrDownloadFile(
                              'entrega',
                              submission['id_entrega'] ?? 0,
                              submission['archivo_ruta'],
                              open: true,
                            );
                          },
                          icon: Icon(Icons.visibility, color: Colors.indigo[600]),
                          label: Text('Ver archivo'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.download, color: Colors.blue),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _openOrDownloadFile(
                            'entrega',
                            submission['id_entrega'] ?? 0,
                            submission['archivo_ruta'],
                            open: false,
                          );
                        },
                        tooltip: 'Descargar archivo',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: Colors.indigo[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                final gradeText = _manualGradeController.text.trim();
                if (gradeText.isEmpty) {
                  _showSnackBar('Por favor ingresa una calificación', Colors.red[600]);
                  return;
                }
               
                final grade = double.tryParse(gradeText) ?? 0.0;
                if (grade < 0 || grade > 100) {
                  _showSnackBar('La calificación debe estar entre 0 y 100', Colors.red[600]);
                  return;
                }
               
                try {
                  print('Guardando calificación $grade para entrega ${submission['id_entrega']}');
                 
                  final updatedDelivery = await _apiService.updateDelivery(
                    deliveryId: submission['id_entrega'] ?? 0,
                    calificacion: grade,
                    observaciones: _commentController.text.isNotEmpty ? _commentController.text : null,
                  );
                 
                  print('Entrega actualizada: $updatedDelivery');
                 
                  // Actualizar la UI
                  setState(() {
                    final updatedSubmission = Map<String, dynamic>.from(submission)
                      ..['calificacion'] = updatedDelivery['calificacion']?.toString() ?? grade.toString()
                      ..['observaciones'] = updatedDelivery['observaciones'] ?? _commentController.text
                      ..['status'] = updatedDelivery['status'] ?? submission['status'];
                   
                    // Actualizar en la lista de entregas
                    _assignments[assignmentIndex]['deliveries'][submissionIndex] = updatedSubmission;
                   
                    // Actualizar contador de calificadas
                    final task = _assignments[assignmentIndex];
                    final entregasCalificadas = (task['deliveries'] as List).where((e) =>
                        e['calificacion'] != null &&
                        e['calificacion'].toString().isNotEmpty &&
                        e['calificacion'] != 'Sin calificar').length;
                   
                    _assignments[assignmentIndex]['calificadas_count'] = entregasCalificadas;
                  });
                 
                  // Limpiar y cerrar
                  _commentController.clear();
                  _manualGradeController.clear();
                  Navigator.pop(context);
                 
                  _showSnackBar('✅ Calificación guardada para ${submission['alumno']}', Colors.green[600]);
                 
                } catch (e) {
                  print('Error al guardar calificación: $e');
                  _showSnackBar('❌ Error al guardar calificación: ${e.toString()}', Colors.red[600]);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[600]),
              child: const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error en _gradeAssignment: $e');
      _showSnackBar('❌ Error al cargar datos de calificación: ${e.toString()}', Colors.red[600]);
    }
  }

  Future<void> _openOrDownloadFile(String resourceType, int resourceId, String filePath, {bool open = true}) async {
    if (filePath == 'Sin archivo' || filePath.isEmpty) {
      _showSnackBar('No hay archivo disponible para ${open ? 'abrir' : 'descargar'}', Colors.red[600]);
      return;
    }
    
    try {
      _showSnackBar(open ? '📖 Abriendo archivo...' : '📥 Descargando archivo...', Colors.blue[600]);
      
      // Opcional: verificar si el archivo existe antes de descargar
      try {
        final bool fileExists = await _apiService.checkFileExists(filePath);
        if (!fileExists) {
          _showSnackBar('⚠️ El archivo no existe en el servidor', Colors.orange);
          return;
        }
      } catch (e) {
        print('Error checking file existence: $e');
        // Continuar con la descarga aunque falle la verificación
      }
      
      // Descargar el archivo usando el método corregido
      final file = await _apiService.downloadFile(
        resourceType: resourceType,
        resourceId: resourceId,
        filePath: filePath,
      );
      
      if (file != null && await file.exists()) {
        final fileSize = await file.length();
        _showSnackBar('✅ Archivo descargado (${(fileSize / 1024).toStringAsFixed(1)} KB)', Colors.green[600]);
        
        if (open) {
          try {
            final result = await OpenFile.open(file.path);
            if (result.type != ResultType.done) {
              _showSnackBar('Archivo descargado. Puedes abrirlo manualmente desde la carpeta Downloads.', Colors.orange);
            }
          } catch (e) {
            print('Error opening file: $e');
            _showSnackBar('Archivo descargado pero no se pudo abrir automáticamente', Colors.orange);
          }
        }
      } else {
        _showSnackBar('❌ No se pudo descargar el archivo', Colors.red[600]);
      }
    } catch (e) {
      print('❌ Error al ${open ? 'abrir' : 'descargar'} archivo: $e');
      
      String errorMessage = 'Error al ${open ? 'abrir' : 'descargar'} archivo';
      if (e.toString().contains('404')) {
        errorMessage = 'El archivo no existe en el servidor.';
      } else if (e.toString().contains('403')) {
        errorMessage = 'No tienes permisos para acceder a este archivo.';
      } else if (e.toString().contains('Connection') || e.toString().contains('internet')) {
        errorMessage = 'Error de conexión. Verifica tu internet.';
      } else if (e.toString().contains('vacío')) {
        errorMessage = 'El archivo está vacío en el servidor.';
      }
      
      _showSnackBar('❌ $errorMessage', Colors.red[600]);
    }
  }

  void _showTaskDetails(int taskIndex) {
    if (taskIndex >= _assignments.length) return;
   
    final task = _assignments[taskIndex];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        title: Text(
          task['title'] ?? 'Sin título',
          style: TextStyle(color: Colors.indigo[900], fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Descripción:',
                style: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.w600),
              ),
              Text(
                task['description'] ?? 'Sin descripción',
                style: TextStyle(color: Colors.indigo[900]),
              ),
              const SizedBox(height: 16),
              Text(
                'Fecha de cierre:',
                style: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.w600),
              ),
              Text(
                '${_formatDateTime(task['due_date'], null)} ${task['due_time'] ?? "23:59"}',
                style: TextStyle(color: Colors.indigo[900]),
              ),
              const SizedBox(height: 16),
              Text(
                'Creador:',
                style: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.w600),
              ),
              Text(
                task['creator'] ?? 'Desconocido',
                style: TextStyle(color: Colors.indigo[900]),
              ),
              const SizedBox(height: 16),
              Text(
                'Estatus:',
                style: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.w600),
              ),
              Text(
                task['status'] ?? 'pending',
                style: TextStyle(
                  color: _getStatusColor(task['status']),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Entregas recibidas:',
                style: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.w600),
              ),
              Text(
                '${(task['deliveries'] as List?)?.length ?? 0} estudiantes',
                style: TextStyle(color: Colors.indigo[900]),
              ),
              if (task['archivo_ruta'] != null &&
                  task['archivo_ruta'].toString().isNotEmpty &&
                  task['archivo_ruta'] != 'Sin archivo') ...[
                const SizedBox(height: 16),
                Text(
                  'Archivo adjunto:',
                  style: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _openOrDownloadFile(
                            'tarea',
                            task['id'],
                            task['archivo_ruta'],
                            open: true,
                          );
                        },
                        icon: Icon(Icons.visibility, color: Colors.indigo[600]),
                        label: Text('Ver archivo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.download, color: Colors.blue),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _openOrDownloadFile(
                          'tarea',
                          task['id'],
                          task['archivo_ruta'],
                          open: false,
                        );
                      },
                      tooltip: 'Descargar archivo',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: TextStyle(color: Colors.indigo[600])),
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
        duration: const Duration(seconds: 3),
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
    if (status == null) return Colors.grey[400]!;
    final statusLower = status.toLowerCase();
   
    if (statusLower == 'entregado' || statusLower == 'delivered' || statusLower == 'ontime' || statusLower == 'a tiempo') {
      return Colors.green[600]!;
    } else if (statusLower == 'pendiente' || statusLower == 'pending') {
      return Colors.orange[600]!;
    } else if (statusLower == 'tarde' || statusLower == 'late') {
      return Colors.red[600]!;
    } else {
      return Colors.grey[400]!;
    }
  }

  Color _getGradeColor(dynamic grade) {
    if (grade == null || grade.toString().isEmpty || grade.toString().toLowerCase() == 'null' || grade == 'Sin calificar') {
      return Colors.grey[400]!;
    }
   
    final doubleGrade = double.tryParse(grade.toString()) ?? 0.0;
    if (doubleGrade >= 90) return Colors.green[600]!;
    if (doubleGrade >= 70) return Colors.blue[600]!;
    if (doubleGrade >= 50) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  String _formatDateTime(String? dateTimeStr, String? timeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return 'Sin fecha';
    try {
      DateTime dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  // Método para parsear fecha límite correctamente
  DateTime _parseDeadlineDateTime(String dateStr, String timeStr) {
    try {
      // Formatear la fecha correctamente
      final datePart = dateStr.split('T')[0];
      final timeParts = timeStr.split(':');
     
      if (timeParts.length >= 2) {
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;
       
        return DateTime.parse('$datePart ${hour.toString().padLeft(2, '0')}:'
                             '${minute.toString().padLeft(2, '0')}:'
                             '${second.toString().padLeft(2, '0')}');
      }
    } catch (e) {
      print('Error parsing deadline: $e');
    }
   
    // Fallback
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  // Ordenar tareas por fecha (más recientes primero)
  List<Map<String, dynamic>> _getSortedAssignments() {
    List<Map<String, dynamic>> sorted = List.from(_assignments);
   
    sorted.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['due_date']?.toString() ?? '');
        final dateB = DateTime.parse(b['due_date']?.toString() ?? '');
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });
   
    return sorted;
  }

  // Obtener tiempo restante
  String _getTimeRemaining(String? dueDate, String? dueTime) {
    if (dueDate == null) return 'Sin fecha';
   
    try {
      final deadline = _parseDeadlineDateTime(dueDate, dueTime ?? '23:59:59');
      final now = DateTime.now();
     
      if (deadline.isBefore(now)) {
        return 'Vencida';
      }
     
      final difference = deadline.difference(now);
     
      if (difference.inDays > 0) {
        return 'Vence en ${difference.inDays} días';
      } else if (difference.inHours > 0) {
        return 'Vence en ${difference.inHours} horas';
      } else {
        return 'Vence en ${difference.inMinutes} minutos';
      }
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  // Obtener color según fecha límite
  Color _getDueDateColor(String? dueDate, String? dueTime) {
    if (dueDate == null) return Colors.grey;
   
    try {
      final deadline = _parseDeadlineDateTime(dueDate, dueTime ?? '23:59:59');
      final now = DateTime.now();
     
      if (deadline.isBefore(now)) {
        return Colors.red;
      }
     
      final difference = deadline.difference(now);
     
      if (difference.inDays <= 1) {
        return Colors.orange;
      } else if (difference.inDays <= 3) {
        return Colors.yellow[700]!;
      } else {
        return Colors.green;
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _filteredSubmissions(List<dynamic> submissions, int taskIndex) {
    if (taskIndex >= _assignments.length) return [];
   
    final task = _assignments[taskIndex];
    final filtered = <Map<String, dynamic>>[];
   
    for (var submission in submissions) {
      try {
        final submissionMap = submission as Map<String, dynamic>;
        final fechaEntregaStr = submissionMap['fecha_entrega']?.toString();
        final calificacion = submissionMap['calificacion'];
       
        if (_filterStatus == 'Todos') {
          filtered.add(submissionMap);
          continue;
        }
       
        // Para filtros que necesitan fecha
        if (fechaEntregaStr != null && fechaEntregaStr.isNotEmpty) {
          try {
            final deliveryDate = DateTime.parse(fechaEntregaStr);
            final taskFecha = task['due_date']?.toString() ?? '';
            final taskHora = task['due_time']?.toString() ?? '23:59:59';
           
            final taskDeadlineDate = _parseDeadlineDateTime(taskFecha, taskHora);
           
            if (_filterStatus == 'A tiempo' &&
                (deliveryDate.isBefore(taskDeadlineDate) ||
                 deliveryDate.isAtSameMomentAs(taskDeadlineDate))) {
              filtered.add(submissionMap);
              continue;
            }
           
            if (_filterStatus == 'Tarde' && deliveryDate.isAfter(taskDeadlineDate)) {
              filtered.add(submissionMap);
              continue;
            }
          } catch (e) {
            print('Error parseando fechas para filtro: $e');
          }
        }
       
        if (_filterStatus == 'Sin calificar') {
          final isUncalified = calificacion == null ||
                               calificacion.toString().isEmpty ||
                               calificacion.toString().toLowerCase() == 'null' ||
                               calificacion == 'Sin calificar';
          if (isUncalified) {
            filtered.add(submissionMap);
          }
        }
       
      } catch (e) {
        print('Error al filtrar entrega: $e');
      }
    }
   
    return filtered;
  }

  void _printDebugInfo() {
    print('=== DEBUG INFO ===');
    print('Número de tareas: ${_assignments.length}');
    for (int i = 0; i < _assignments.length; i++) {
      final task = _assignments[i];
      print('\nTarea $i: ${task['title']}');
      print(' ID: ${task['id']}');
      print(' Status: ${task['status']}');
      print(' Fecha entrega: ${task['due_date']}');
      print(' Hora cierre: ${task['due_time']}');
      print(' Archivo: ${task['archivo_ruta']}');
     
      final entregas = task['deliveries'] as List<dynamic>? ?? [];
      print(' Número de entregas: ${entregas.length}');
     
      for (int j = 0; j < entregas.length; j++) {
        final entrega = entregas[j] as Map<String, dynamic>;
        print(' Entrega $j:');
        print(' Alumno: ${entrega['alumno']}');
        print(' ID Alumno: ${entrega['id_alumno']}');
        print(' Calificación: ${entrega['calificacion']}');
        print(' Observaciones: ${entrega['observaciones']}');
        print(' Fecha entrega: ${entrega['fecha_entrega']}');
        print(' ID Entrega: ${entrega['id_entrega']}');
        print(' Archivo: ${entrega['archivo_ruta']}');
      }
    }
    print('\nNúmero de avisos: ${_announcements.length}');
    for (var aviso in _announcements) {
      print(' Aviso: ${aviso['titulo']} - ${aviso['usuario']}');
    }
    print('=================\n');
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
                    widget.navBarVisibilityNotifier!.value = false;
                  } else if (currentOffset < _lastScrollOffset - 8 && !widget.navBarVisibilityNotifier!.value && currentOffset > 0) {
                    widget.navBarVisibilityNotifier!.value = true;
                  } else if (currentOffset <= 0 && !widget.navBarVisibilityNotifier!.value) {
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
                                'Subir archivo (opcional)',
                                style: TextStyle(color: Colors.indigo[700], fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _pickFile,
                                icon: Icon(
                                  _selectedFile == null ? Icons.upload : Icons.check_circle,
                                  color: _selectedFile == null ? Colors.indigo[600] : Colors.green[600],
                                ),
                                label: Text(
                                  _selectedFile == null ? 'Seleccionar archivo' : 'Archivo seleccionado',
                                  style: TextStyle(
                                    color: _selectedFile == null ? Colors.indigo[600] : Colors.green[600],
                                    fontWeight: _selectedFile == null ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: _selectedFile == null ? Colors.indigo[600]! : Colors.green[600]!,
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                              if (_selectedFile != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${_selectedFile!.path.split('/').last}',
                                  style: TextStyle(color: Colors.green[700], fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
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
                                          task['title'] ?? 'Sin título',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.indigo[900]),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Entrega: ${_formatDateTime(task['due_date'], null)} ${task['due_time']}',
                                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                            ),
                                            Text(
                                              'Entregas: ${(task['deliveries'] as List?)?.length ?? 0} estudiantes',
                                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                            ),
                                          ],
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
                          widget.navBarVisibilityNotifier!.value = false;
                        } else if (currentOffset < _lastScrollOffset - 8 && !widget.navBarVisibilityNotifier!.value && currentOffset > 0) {
                          widget.navBarVisibilityNotifier!.value = true;
                        } else if (currentOffset <= 0 && !widget.navBarVisibilityNotifier!.value) {
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
                            child: Row(
                              children: [
                                const Icon(Icons.filter_list, color: Colors.indigo),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButton<String>(
                                    value: _filterStatus,
                                    isExpanded: true,
                                    items: _statusFilters.map((String status) {
                                      return DropdownMenuItem<String>(
                                        value: status,
                                        child: Text(status),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() => _filterStatus = newValue!);
                                    },
                                    underline: Container(height: 1, color: Colors.indigo[200]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_assignments.isEmpty)
                          SliverFillRemaining(
                            child: Center(
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
                            ),
                          )
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, assignmentIndex) {
                                final sortedAssignments = _getSortedAssignments();
                                final assignment = sortedAssignments[assignmentIndex];
                                // Encontrar el índice original
                                final originalIndex = _assignments.indexWhere((a) => a['id'] == assignment['id']);
                                final filteredSubmissions = _filteredSubmissions(assignment['deliveries'] ?? [], originalIndex);
                               
                                return FadeTransition(
                                  opacity: _fadeAnimation,
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    color: Colors.white,
                                    child: ExpansionTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.indigo[100],
                                        child: Icon(Icons.assignment, color: Colors.indigo[600]),
                                      ),
                                      title: Text(
                                        assignment['title'] ?? 'Sin título',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo[900]),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Entrega: ${_formatDateTime(assignment['due_date'], null)} ${assignment['due_time']}',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _getTimeRemaining(assignment['due_date'], assignment['due_time']),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: _getDueDateColor(assignment['due_date'], assignment['due_time']),
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo[600]!.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${filteredSubmissions.length}',
                                          style: TextStyle(color: Colors.indigo[600], fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      children: [
                                        if (filteredSubmissions.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Text(
                                              _filterStatus == 'Todos'
                                                ? 'No hay entregas para esta tarea'
                                                : 'No hay entregas con el filtro "$_filterStatus"',
                                              style: TextStyle(color: Colors.grey[600]),
                                              textAlign: TextAlign.center,
                                            ),
                                          )
                                        else
                                          ...filteredSubmissions.asMap().entries.map((entry) {
                                            final submissionIndex = entry.key;
                                            final submission = entry.value;
                                           
                                            final fechaEntregaStr = submission['fecha_entrega']?.toString();
                                            DateTime? fechaEntrega;
                                            if (fechaEntregaStr != null && fechaEntregaStr.isNotEmpty) {
                                              try {
                                                fechaEntrega = DateTime.parse(fechaEntregaStr);
                                              } catch (e) {
                                                print('Error parseando fecha entrega: $e');
                                              }
                                            }
                                           
                                            final taskFecha = assignment['due_date']?.toString() ?? '';
                                            final taskHora = assignment['due_time']?.toString() ?? '23:59:59';
                                           
                                            bool isOnTime = false;
                                            if (fechaEntrega != null) {
                                              final taskDeadlineDate = _parseDeadlineDateTime(taskFecha, taskHora);
                                              isOnTime = fechaEntrega.isBefore(taskDeadlineDate) ||
                                                         fechaEntrega.isAtSameMomentAs(taskDeadlineDate);
                                            }
                                           
                                            return Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: isOnTime ? Colors.green[50] : Colors.orange[50],
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: isOnTime ? Colors.green[200]! : Colors.orange[200]!,
                                                ),
                                              ),
                                              child: ListTile(
                                                leading: CircleAvatar(
                                                  backgroundColor: Colors.indigo[100],
                                                  child: Text(
                                                    (submission['alumno'] ?? 'E').substring(0, 1).toUpperCase(),
                                                    style: TextStyle(color: Colors.indigo[600]),
                                                  ),
                                                ),
                                                title: Text(
                                                  submission['alumno'] ?? 'Desconocido',
                                                  style: TextStyle(fontWeight: FontWeight.w600),
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (fechaEntrega != null)
                                                      Text(
                                                        'Entregado: ${DateFormat('dd MMM yyyy HH:mm').format(fechaEntrega)}',
                                                        style: TextStyle(fontSize: 12),
                                                      ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: isOnTime ? Colors.green[100]! : Colors.orange[100]!,
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Text(
                                                            isOnTime ? 'A tiempo' : 'Tarde',
                                                            style: TextStyle(
                                                              color: isOnTime ? Colors.green[800] : Colors.orange[800],
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                        if (submission['calificacion'] != null &&
                                                            submission['calificacion'].toString().isNotEmpty &&
                                                            submission['calificacion'].toString().toLowerCase() != 'null' &&
                                                            submission['calificacion'] != 'Sin calificar')
                                                          Padding(
                                                            padding: const EdgeInsets.only(left: 8),
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                              decoration: BoxDecoration(
                                                                color: _getGradeColor(submission['calificacion']),
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                              child: Text(
                                                                (double.tryParse(submission['calificacion'].toString()) ?? 0.0)
                                                                    .toStringAsFixed(0),
                                                                style: const TextStyle(
                                                                  color: Colors.white,
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 12,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    if (submission['observaciones'] != null &&
                                                        submission['observaciones'].toString().isNotEmpty &&
                                                        submission['observaciones'] != 'Sin observaciones')
                                                      Padding(
                                                        padding: const EdgeInsets.only(top: 4),
                                                        child: Text(
                                                          '"${submission['observaciones']}"',
                                                          style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                trailing: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(
                                                        (submission['calificacion'] == null ||
                                                         submission['calificacion'].toString().isEmpty ||
                                                         submission['calificacion'] == 'Sin calificar')
                                                          ? Icons.grading
                                                          : Icons.edit,
                                                        color: Colors.indigo[600],
                                                      ),
                                                      onPressed: () => _gradeAssignment(originalIndex, submissionIndex),
                                                    ),
                                                    if (submission['archivo_ruta'] != null &&
                                                        submission['archivo_ruta'].toString().isNotEmpty &&
                                                        submission['archivo_ruta'] != 'Sin archivo')
                                                      IconButton(
                                                        icon: Icon(Icons.download, color: Colors.blue[600]),
                                                        onPressed: () => _openOrDownloadFile(
                                                          'entrega',
                                                          submission['id_entrega'] ?? 0,
                                                          submission['archivo_ruta'],
                                                          open: false,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: _assignments.isEmpty ? 0 : _getSortedAssignments().length,
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
                          widget.navBarVisibilityNotifier!.value = false;
                        } else if (currentOffset < _lastScrollOffset - 8 && !widget.navBarVisibilityNotifier!.value && currentOffset > 0) {
                          widget.navBarVisibilityNotifier!.value = true;
                        } else if (currentOffset <= 0 && !widget.navBarVisibilityNotifier!.value) {
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
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _announcementTextController,
                                      maxLines: 4,
                                      decoration: _inputDecoration('Texto del aviso', Icons.announcement),
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
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.announcement_outlined, size: 60, color: Colors.indigo[300]),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No hay avisos publicados',
                                    style: TextStyle(fontSize: 18, color: Colors.indigo[600]),
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._announcements.asMap().entries.map((entry) {
                              final index = entry.key;
                              final announcement = entry.value;
                             
                              String fechaHora = '';
                              if (announcement['fecha_hora'] != null && announcement['fecha_hora'].toString().isNotEmpty) {
                                try {
                                  final fecha = DateTime.parse(announcement['fecha_hora'].toString());
                                  fechaHora = DateFormat('dd MMM yyyy HH:mm').format(fecha);
                                } catch (e) {
                                  fechaHora = announcement['fecha_hora'].toString();
                                }
                              }
                             
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  color: Colors.white,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.indigo[100],
                                      child: Icon(Icons.announcement, color: Colors.indigo[600]),
                                    ),
                                    title: Text(
                                      announcement['titulo'] ?? 'Sin título',
                                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo[900]),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(announcement['texto'] ?? ''),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Por: ${announcement['usuario'] ?? 'Desconocido'}',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                        Text(
                                          'Fecha: $fechaHora',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit, color: Colors.indigo[600]),
                                          onPressed: () => _editAnnouncement(index),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red[600]),
                                          onPressed: () => _deleteAnnouncement(index),
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
        floatingActionButton: _currentTab == 0 && _assignments.isNotEmpty
            ? FloatingActionButton(
                onPressed: () {
                  _tab1ScrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                backgroundColor: Colors.indigo[600],
                child: const Icon(Icons.arrow_upward, color: Colors.white),
              )
            : null,
      ),
    );
  }
}