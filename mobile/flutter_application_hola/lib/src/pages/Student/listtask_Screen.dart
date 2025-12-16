import 'package:flutter/material.dart';
import 'package:flutter_application_hola/src/models/TaskStatus.dart';
import 'package:flutter_application_hola/src/pages/Student/task_screen.dart';
import 'package:flutter_application_hola/src/services/api_task_services.dart';
import 'package:intl/intl.dart';

class ListTaskScreen extends StatefulWidget {
  final int userId;
  final String userRole;

  const ListTaskScreen({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<ListTaskScreen> createState() => _ListTaskScreenState();
}

class _ListTaskScreenState extends State<ListTaskScreen> {
  late Future<List<TaskGroup>> _tasksFuture;
  final ApiTaskServices _apiService = ApiTaskServices();
  bool _isLoading = true;
  String _errorMessage = '';
  TaskFilter _currentFilter = TaskFilter.recent;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    
    // Añadir listener para debug
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugCurrentState();
    });
  }

  void _debugCurrentState() {
    print('=== DEBUG ListTaskScreen ===');
    print('  User ID: ${widget.userId}');
    print('  User Role: ${widget.userRole}');
    print('  Current Filter: $_currentFilter');
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('=== Loading tasks for user ${widget.userId} ===');
      
      final tasksData = await _apiService.displayTasks(
        userId: widget.userId,
        userRole: widget.userRole,
      );

      print('✅ Datos de tareas recibidos: ${tasksData.length} tareas');
      
      for (var task in tasksData) {
        print('Task ID: ${task['id']}, Title: ${task['titulo']}');
        print('  Status: ${task['status']}');
        print('  Deliveries: ${task['entregas']?.length ?? 0}');
        if (task['entregas'] != null && task['entregas'].isNotEmpty) {
          print('  First delivery: ${task['entregas'][0]}');
        }
      }

      final taskGroups = _organizeTasksByDate(tasksData);
      
      print('✅ Task groups organized: ${taskGroups.length} groups');

      setState(() {
        _tasksFuture = Future.value(taskGroups);
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error en _loadTasks: $e');
      setState(() {
        _errorMessage = 'Error al cargar tareas: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<TaskGroup> _organizeTasksByDate(List<Map<String, dynamic>> tasksData) {
    print('=== Organizing tasks by date ===');
    final Map<String, List<Task>> groupedTasks = {};

    for (final taskData in tasksData) {
      try {
        print('Processing task data: ${taskData['id']} - ${taskData['titulo']}');
        
        final task = Task.fromApi(taskData);
        
        // Aplicar filtro
        if (_currentFilter == TaskFilter.pending && task.status == TaskStatus.delivered) {
          print('  Skipping - Filter: pending, Status: delivered');
          continue;
        }
        if (_currentFilter == TaskFilter.delivered && task.status != TaskStatus.delivered) {
          print('  Skipping - Filter: delivered, Status: ${task.status}');
          continue;
        }
        
        final dateKey = DateFormat('yyyy-MM-dd').format(task.dueDate);
        print('  Date key: $dateKey');

        if (!groupedTasks.containsKey(dateKey)) {
          groupedTasks[dateKey] = [];
        }
        groupedTasks[dateKey]!.add(task);
        print('  ✅ Task added to group');
      } catch (e) {
        print('❌ Error procesando tarea: $e');
        print('  Datos: $taskData');
      }
    }

    final groups = groupedTasks.entries.map((entry) {
      return TaskGroup(
        date: DateTime.parse(entry.key),
        tasks: entry.value,
      );
    }).toList()
      ..sort((a, b) => _currentFilter == TaskFilter.recent 
          ? b.date.compareTo(a.date) 
          : a.date.compareTo(b.date));
    
    print('✅ Created ${groups.length} task groups');
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo[50],
      appBar: AppBar(
        title: const Text(
          'Mis Tareas',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.indigo,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTasks,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.indigo[700],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFilterButton('Recientes', TaskFilter.recent),
          _buildFilterButton('Pendientes', TaskFilter.pending),
          _buildFilterButton('Entregados', TaskFilter.delivered),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text, TaskFilter filter) {
    final isSelected = _currentFilter == filter;
    
    return TextButton(
      onPressed: () {
        print('Filter changed to: $filter');
        setState(() {
          _currentFilter = filter;
        });
        _loadTasks();
      },
      style: TextButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : Colors.white70,
        backgroundColor: isSelected ? Colors.indigo[500] : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
            ),
            SizedBox(height: 16),
            Text(
              'Cargando tareas...',
              style: TextStyle(color: Colors.indigo),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar tareas',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.indigo[900],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.indigo[700]),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadTasks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<List<TaskGroup>>(
      future: _tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${snapshot.error}', 
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.indigo[900]),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadTasks,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.indigo[300],
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(),
                  style: TextStyle(
                    fontSize: 18, 
                    color: Colors.indigo[900],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _getEmptySubtitle(),
                  style: TextStyle(color: Colors.indigo[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final taskGroups = snapshot.data!;

        return RefreshIndicator(
          color: Colors.indigo,
          onRefresh: _loadTasks,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: taskGroups.length,
            itemBuilder: (context, index) {
              final group = taskGroups[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateHeader(group.date),
                  ...group.tasks
                      .map((task) => _buildTaskCard(context, task))
                      .toList(),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _getEmptyMessage() {
    switch (_currentFilter) {
      case TaskFilter.pending:
        return 'No hay tareas pendientes';
      case TaskFilter.delivered:
        return 'No hay tareas entregadas';
      case TaskFilter.recent:
      default:
        return 'No hay tareas disponibles';
    }
  }

  String _getEmptySubtitle() {
    switch (_currentFilter) {
      case TaskFilter.pending:
        return '¡Excelente! Has entregado todas tus tareas';
      case TaskFilter.delivered:
        return 'Aún no has entregado ninguna tarea';
      case TaskFilter.recent:
      default:
        return 'Cuando tengas tareas asignadas, aparecerán aquí';
    }
  }

  Widget _buildDateHeader(DateTime date) {
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isPast = date.isBefore(DateTime(today.year, today.month, today.day)) && !isToday;
    final isTomorrow = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day + 1;

    String dateText;
    if (isToday) {
      dateText = 'Hoy';
    } else if (isTomorrow) {
      dateText = 'Mañana';
    } else if (isPast) {
      dateText = 'Vencidas';
    } else {
      dateText = DateFormat('EEEE, d MMMM yyyy').format(date);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isToday
            ? Colors.indigo[100]
            : isPast
                ? Colors.red[50]
                : Colors.indigo[50],
        border: Border(
          bottom: BorderSide(
            color: isToday
                ? Colors.indigo[200]!
                : isPast
                    ? Colors.red[100]!
                    : Colors.indigo[100]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 18,
            color: isToday
                ? Colors.indigo[800]
                : isPast
                    ? Colors.red[400]
                    : Colors.indigo[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isToday
                    ? Colors.indigo[800]
                    : isPast
                        ? Colors.red[600]
                        : Colors.indigo[600],
              ),
            ),
          ),
          if (!isToday && !isPast && !isTomorrow)
            Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: TextStyle(
                fontSize: 14,
                color: Colors.indigo[400],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    print('=== Building task card ===');
    print('  Task ID: ${task.id} - ${task.title}');
    print('  Status: ${task.status}');
    print('  Deliveries count: ${task.deliveries.length}');
    if (task.deliveries.isNotEmpty) {
      print('  First delivery: ${task.deliveries.first}');
    }
    
    final isDelivered = task.status == TaskStatus.delivered;
    final description = task.description;
    final isPastDue = task.isExpired && !isDelivered;
    final hasCalificacion = task.deliveries.isNotEmpty && 
        task.deliveries.first['calificacion'] != null &&
        task.deliveries.first['calificacion'] != 'Sin calificar';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _showTaskDetails(context, task);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: isPastDue ? Colors.red[800] : Colors.indigo[900],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDelivered 
                            ? (hasCalificacion ? Colors.green[50] : Colors.blue[50])
                            : isPastDue 
                                ? Colors.red[50] 
                                : Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDelivered 
                              ? (hasCalificacion ? Colors.green[100]! : Colors.blue[100]!)
                              : isPastDue
                                  ? Colors.red[100]!
                                  : Colors.orange[100]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isDelivered 
                            ? (hasCalificacion ? 'CALIFICADA' : 'ENTREGADA')
                            : isPastDue
                                ? 'VENCIDA'
                                : 'PENDIENTE',
                        style: TextStyle(
                          color: isDelivered 
                              ? (hasCalificacion ? Colors.green[800] : Colors.blue[800])
                              : isPastDue
                                  ? Colors.red[800]
                                  : Colors.orange[800],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  task.creator,
                  style: TextStyle(
                    color: Colors.indigo[700],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.indigo[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      task.formattedDueDate,
                      style: TextStyle(
                        color: isPastDue 
                            ? Colors.red[700] 
                            : Colors.indigo[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.indigo[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      task.dueTime ?? '23:59',
                      style: TextStyle(
                        color: isPastDue 
                            ? Colors.red[700] 
                            : Colors.indigo[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (isDelivered && task.deliveries.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDeliveryInfo(task.deliveries.first),
                ],
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.indigo[800],
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (task.filePath != null && task.filePath != 'Sin archivo') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.attach_file,
                        size: 16,
                        color: Colors.indigo[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Archivo adjunto: ${task.filePath!.split('/').last}',
                          style: TextStyle(
                            color: Colors.indigo[600],
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      _showTaskDetails(context, task);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Ver Tarea',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildDeliveryInfo(Map<String, dynamic> delivery) {
    final calificacion = delivery['calificacion'];
    final observaciones = delivery['observaciones'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (calificacion != null && calificacion != 'Sin calificar') ...[
          Row(
            children: [
              Icon(
                Icons.grade,
                size: 16,
                color: Colors.amber[600],
              ),
              const SizedBox(width: 6),
              Text(
                'Calificación: $calificacion',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        if (observaciones != null && 
            observaciones != 'Sin observaciones' && 
            observaciones.toString().isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.comment,
                size: 16,
                color: Colors.indigo[500],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Obs: ${observaciones.toString()}',
                  style: TextStyle(
                    color: Colors.indigo[700],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    print('Navigating to TaskScreen for task ${task.id}');
    print('Task deliveries: ${task.deliveries}');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskScreen(
          task: task,
          userId: widget.userId,
          taskId: task.id,
          userRole: widget.userRole,
        ),
      ),
    ).then((_) {
      _loadTasks();
    });
  }
}

enum TaskFilter {
  recent,
  pending,
  delivered,
}