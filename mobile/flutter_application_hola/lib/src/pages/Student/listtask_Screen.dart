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
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final tasksData = await _apiService.displayTasks(
        userId: widget.userId,
        userRole: widget.userRole,
      );

      print('Datos de tareas recibidos: ${tasksData.length} tareas');

      final taskGroups = _organizeTasksByDate(tasksData);

      setState(() {
        _tasksFuture = Future.value(taskGroups);
        _isLoading = false;
      });
    } catch (e) {
      print('Error en _loadTasks: $e');
      setState(() {
        _errorMessage = 'Error al cargar tareas: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<TaskGroup> _organizeTasksByDate(List<dynamic> tasksData) {
    final Map<String, List<Task>> groupedTasks = {};

    for (final taskData in tasksData) {
      try {
        final task = Task.fromApi(taskData);
        
        // Aplicar filtro
        if (_currentFilter == TaskFilter.pending && task.status == TaskStatus.delivered) {
          continue;
        }
        if (_currentFilter == TaskFilter.delivered && task.status != TaskStatus.delivered) {
          continue;
        }
        
        final dateKey = DateFormat('yyyy-MM-dd').format(task.dueDate);

        if (!groupedTasks.containsKey(dateKey)) {
          groupedTasks[dateKey] = [];
        }
        groupedTasks[dateKey]!.add(task);
      } catch (e) {
        print('Error procesando tarea: $e - Datos: $taskData');
      }
    }

    return groupedTasks.entries.map((entry) {
      return TaskGroup(
        date: DateTime.parse(entry.key),
        tasks: entry.value,
      );
    }).toList()
      ..sort((a, b) => _currentFilter == TaskFilter.recent 
          ? b.date.compareTo(a.date) 
          : a.date.compareTo(b.date));
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
        setState(() {
          _currentFilter = filter;
          _loadTasks();
        });
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
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage, 
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
                Icon(Icons.assignment, size: 48, color: Colors.indigo[300]),
                const SizedBox(height: 16),
                Text(
                  'No hay tareas disponibles',
                  style: TextStyle(
                    fontSize: 18, 
                    color: Colors.indigo[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cuando tengas tareas, aparecerán aquí',
                  style: TextStyle(color: Colors.indigo[700]),
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

  Widget _buildDateHeader(DateTime date) {
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isPast = date.isBefore(today) && !isToday;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        border: Border(
          bottom: BorderSide(color: Colors.indigo[100]!, width: 1),
          top: BorderSide(color: Colors.indigo[100]!, width: 1),
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
                    ? Colors.indigo[400]
                    : Colors.indigo[600],
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('EEEE, d MMMM yyyy').format(date),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isToday
                  ? Colors.indigo[800]
                  : isPast
                      ? Colors.indigo[400]
                      : Colors.indigo[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    final isDelivered = task.status == TaskStatus.delivered;
    final description = task.description;
    final isPastDue = task.dueDate.isBefore(DateTime.now()) && !isDelivered;

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
                            ? Colors.green[50] 
                            : isPastDue 
                                ? Colors.red[50] 
                                : Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDelivered 
                              ? Colors.green[100]! 
                              : isPastDue
                                  ? Colors.red[100]!
                                  : Colors.orange[100]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isDelivered 
                            ? 'ENTREGADO' 
                            : isPastDue
                                ? 'VENCIDO'
                                : 'PENDIENTE',
                        style: TextStyle(
                          color: isDelivered 
                              ? Colors.green[800] 
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
                      DateFormat('dd MMM yyyy').format(task.dueDate),
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
                      task.dueTime?.isNotEmpty == true ? task.dueTime! : '23:59',
                      style: TextStyle(
                        color: isPastDue 
                            ? Colors.red[700] 
                            : Colors.indigo[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
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
                      Text(
                        'Archivo adjunto: ${task.filePath!.split('/').last}',
                        style: TextStyle(
                          color: Colors.indigo[600],
                          fontSize: 14,
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

  void _showTaskDetails(BuildContext context, Task task) {
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

class TaskGroup {
  final DateTime date;
  final List<Task> tasks;

  TaskGroup({
    required this.date,
    required this.tasks,
  });
}