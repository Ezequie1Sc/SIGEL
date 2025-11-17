import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_application_hola/src/services/api_task_services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda Escolar',
      theme: ThemeData(
        primaryColor: Colors.indigo[800],
        scaffoldBackgroundColor: Colors.indigo[50],
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.indigo,
          backgroundColor: Colors.indigo[50],
        ).copyWith(surface: Colors.white),
      ),
      home: const ScheduleScreen(userId: 1, userRole: 'alumno'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  final int userId;
  final String userRole;

  const ScheduleScreen({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  bool _showCalendar = true;
  bool _showFab = false;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ApiTaskServices _apiService = ApiTaskServices();

  List<Tarea> _tareas = [];
  List<Publicacion> _publicaciones = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null);
    _scrollController.addListener(_handleScroll);
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Cargar tareas
      final tasksData = await _apiService.displayTasks(
        userId: widget.userId,
        userRole: widget.userRole,
      );
      final tasks = tasksData.map((task) => Tarea.fromApi(task)).toList();

      // Cargar publicaciones
      final announcementsData = await _apiService.getAllAnnouncements();
      final announcements = announcementsData.map((ann) => Publicacion.fromApi(ann)).toList();

      setState(() {
        _tareas = tasks;
        _publicaciones = announcements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar datos: $e';
        _isLoading = false;
      });
    }
  }

  void _handleScroll() {
    if (_scrollController.offset > 100 && _showCalendar) {
      setState(() {
        _showCalendar = false;
        _showFab = true;
      });
    } else if (_scrollController.offset <= 100 && !_showCalendar) {
      setState(() {
        _showCalendar = true;
        _showFab = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tareasFiltradas = _tareas.where((tarea) => isSameDay(tarea.fecha, _selectedDate)).toList();
    final publicacionesFiltradas = _publicaciones.where((pub) => isSameDay(pub.fecha, _selectedDate)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda Escolar', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.indigo[800],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Tareas', icon: Icon(Icons.assignment)),
            Tab(text: 'Publicaciones', icon: Icon(Icons.announcement)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage, textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Calendario fijo en la parte superior
                    if (_showCalendar) _buildCalendar(),
                    
                    // Contenido de las pestañas
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTareasView(tareasFiltradas),
                          _buildPublicacionesView(publicacionesFiltradas),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _showFab
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              backgroundColor: Colors.indigo[800],
              child: const Icon(Icons.calendar_today, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildCalendar() {
    // Contar tareas del mes actual
    final tareasDelMes = _tareas.where((tarea) => 
        tarea.fecha.year == _selectedDate.year && 
        tarea.fecha.month == _selectedDate.month).length;

    // Contar publicaciones del mes actual
    final publicacionesDelMes = _publicaciones.where((pub) => 
        pub.fecha.year == _selectedDate.year && 
        pub.fecha.month == _selectedDate.month).length;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Encabezado con contadores
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCounterItem(
                  'Tareas del Mes',
                  tareasDelMes.toString(),
                  Colors.blue,
                  Icons.assignment,
                ),
                _buildCounterItem(
                  'Avisos del Mes',
                  publicacionesDelMes.toString(),
                  Colors.orange,
                  Icons.announcement,
                ),
              ],
            ),
          ),
          // Calendario
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _selectedDate,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
              });
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Colors.indigo[800],
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.indigo[100],
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: Colors.indigo[800]),
              markersAlignment: Alignment.topCenter,
              markersAutoAligned: false,
              markerSize: 6,
              markerMargin: const EdgeInsets.only(top: 2),
              markerDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: Colors.indigo[800],
                fontWeight: FontWeight.bold,
              ),
              weekendStyle: TextStyle(
                color: Colors.indigo[800],
                fontWeight: FontWeight.bold,
              ),
            ),
            headerStyle: HeaderStyle(
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[800],
              ),
              formatButtonVisible: false,
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.indigo[800]),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.indigo[800]),
            ),
            eventLoader: (day) {
              final hasTareas = _tareas.any((tarea) => isSameDay(tarea.fecha, day));
              final hasPublicaciones = _publicaciones.any((pub) => isSameDay(pub.fecha, day));

              if (hasTareas && hasPublicaciones) {
                return ['Tarea y Publicación'];
              } else if (hasTareas) {
                return ['Tarea'];
              } else if (hasPublicaciones) {
                return ['Publicación'];
              }
              return [];
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final hasTareas = _tareas.any((tarea) => isSameDay(tarea.fecha, date));
                final hasPublicaciones = _publicaciones.any((pub) => isSameDay(pub.fecha, date));

                if (hasTareas && hasPublicaciones) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  );
                } else if (hasTareas) {
                  return Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  );
                } else if (hasPublicaciones) {
                  return Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterItem(String title, String count, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.indigo[800],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTareasView(List<Tarea> tareasFiltradas) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        if (tareasFiltradas.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 60, color: Colors.blue[300]),
                const SizedBox(height: 12),
                Text(
                  'No hay tareas para este día',
                  style: TextStyle(fontSize: 16, color: Colors.blue[600]),
                ),
              ],
            ),
          )
        else
          ...tareasFiltradas.asMap().entries.map((entry) {
            final index = entry.key;
            final tarea = entry.value;
            return FadeTransition(
              opacity: _fadeAnimation,
              child: _buildTareaCard(tarea, index),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildPublicacionesView(List<Publicacion> publicacionesFiltradas) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        if (publicacionesFiltradas.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.announcement_outlined, size: 60, color: Colors.amber[300]),
                const SizedBox(height: 12),
                Text(
                  'No hay publicaciones para este día',
                  style: TextStyle(fontSize: 16, color: Colors.amber[600]),
                ),
              ],
            ),
          )
        else
          ...publicacionesFiltradas.asMap().entries.map((entry) {
            final index = entry.key;
            final publicacion = entry.value;
            return FadeTransition(
              opacity: _fadeAnimation,
              child: _buildPublicacionCard(publicacion, index),
            );
          }).toList(),
      ],
    );
  }

  Widget _buildTareaCard(Tarea tarea, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.blue, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tarea.materia ?? 'Sin materia',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tarea.entregado ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tarea.entregado ? 'ENTREGADO' : 'PENDIENTE',
                    style: TextStyle(
                      color: tarea.entregado ? Colors.green[700] : Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tarea.titulo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tarea.descripcion ?? 'Sin descripción',
              style: TextStyle(fontSize: 14, color: Colors.indigo[700]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.event, size: 16, color: Colors.blue[500]),
                const SizedBox(width: 6),
                Text(
                  DateFormat('d MMM yyyy', 'es').format(tarea.fecha),
                  style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicacionCard(Publicacion publicacion, int index) {
    Color tipoColor;
    IconData tipoIcon;
    switch (publicacion.tipo) {
      case TipoPublicacion.urgente:
        tipoColor = Colors.red;
        tipoIcon = Icons.warning;
        break;
      case TipoPublicacion.material:
        tipoColor = Colors.blue;
        tipoIcon = Icons.book;
        break;
      case TipoPublicacion.aviso:
      default:
        tipoColor = Colors.orange;
        tipoIcon = Icons.announcement;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange[700]!, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange[100],
                  child: Icon(tipoIcon, color: tipoColor, size: 20),
                  radius: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        publicacion.profesor ?? 'Desconocido',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[900],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        publicacion.materia ?? 'Sin materia',
                        style: TextStyle(fontSize: 12, color: Colors.indigo[700]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tipoColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    publicacion.tipo.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: tipoColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              publicacion.titulo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[900],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              publicacion.contenido,
              style: TextStyle(fontSize: 14, color: Colors.indigo[700]),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.event, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 6),
                Text(
                  DateFormat('d MMM yyyy', 'es').format(publicacion.fecha),
                  style: TextStyle(fontSize: 12, color: Colors.orange[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

enum TipoPublicacion {
  aviso,
  material,
  urgente,
}

class Tarea {
  final int id;
  final String titulo;
  final String? descripcion;
  final DateTime fecha;
  final String? materia;
  final bool entregado;
  final Color color;

  Tarea({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.fecha,
    this.materia,
    required this.entregado,
    required this.color,
  });

  factory Tarea.fromApi(Map<String, dynamic> data) {
    return Tarea(
      id: data['id'] ?? 0,
      titulo: data['title'] ?? 'Sin título',
      descripcion: data['description'],
      fecha: DateTime.parse(data['due_date'] ?? DateTime.now().toString()),
      materia: data['creator'] ?? 'Sin materia',
      entregado: data['status']?.toLowerCase() == 'entregado' || data['deliveries']?.isNotEmpty == true,
      color: Colors.blue,
    );
  }
}

class Publicacion {
  final int id;
  final String titulo;
  final String contenido;
  final DateTime fecha;
  final String? profesor;
  final String? materia;
  final TipoPublicacion tipo;

  Publicacion({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.fecha,
    this.profesor,
    this.materia,
    required this.tipo,
  });

  factory Publicacion.fromApi(Map<String, dynamic> data) {
    TipoPublicacion tipo;
    switch ((data['tipo'] ?? 'aviso').toString().toLowerCase()) {
      case 'urgente':
        tipo = TipoPublicacion.urgente;
        break;
      case 'material':
        tipo = TipoPublicacion.material;
        break;
      case 'aviso':
      default:
        tipo = TipoPublicacion.aviso;
    }

    return Publicacion(
      id: data['id'] ?? 0,
      titulo: data['titulo'] ?? 'Sin título',
      contenido: data['texto'] ?? 'Sin contenido',
      fecha: DateTime.parse(data['fecha_creacion'] ?? DateTime.now().toString()),
      profesor: data['usuario'] != null
          ? '${data['usuario']['nombre'] ?? ''} ${data['usuario']['apellido'] ?? ''}'.trim()
          : 'Desconocido',
      materia: data['materia'] ?? 'Sin materia',
      tipo: tipo,
    );
  }
}