import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const TeacheralumScreen());
}

class TeacheralumScreen extends StatelessWidget {
  const TeacheralumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Equipos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          background: Colors.white,
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.indigo),
          ),
          filled: true,
          fillColor: Colors.indigo[50],
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Colors.indigo),
        ),
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        useMaterial3: true,
      ),
      home: const TeamManagementScreen(),
    );
  }
}

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  int _idCounter = 0;

  String _generateId() {
    return (_idCounter++).toString();
  }

  // Lista de colores para diferenciar equipos (dentro de la paleta índigo y tonos complementarios)
  final List<Color> _teamColors = [
    Colors.indigo[400]!,
    Colors.indigo[600]!,
    Colors.blue[400]!,
    Colors.blue[600]!,
    Colors.purple[400]!,
    Colors.purple[600]!,
  ];

  final List<Student> _students = [
    Student(id: '1', name: 'María García', avatar: 'MG'),
    Student(id: '2', name: 'Juan Pérez', avatar: 'JP'),
    Student(id: '3', name: 'Ana López', avatar: 'AL'),
    Student(id: '4', name: 'Carlos Ruiz', avatar: 'CR'),
    Student(id: '5', name: 'Sofía Martín', avatar: 'SM'),
    Student(id: '6', name: 'David González', avatar: 'DG'),
    Student(id: '7', name: 'Laura Fernández', avatar: 'LF'),
    Student(id: '8', name: 'Pablo Rodríguez', avatar: 'PR'),
  ];

  final List<Team> _teams = [];
  final _teamNameController = TextEditingController();
  final _maxMembersController = TextEditingController(text: '4');

  @override
  void dispose() {
    _teamNameController.dispose();
    _maxMembersController.dispose();
    super.dispose();
  }

  void _showCreateTeamDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: const Text('Crear Nuevo Equipo', style: TextStyle(color: Colors.indigo)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _teamNameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Equipo',
                hintText: 'Ej: Equipo Dinámico',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _maxMembersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Máximo de Integrantes',
                hintText: 'Ej: 4',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.indigo)),
          ),
          ElevatedButton(
            onPressed: () {
              final teamName = _teamNameController.text.trim();
              final maxMembers = int.tryParse(_maxMembersController.text) ?? 0;
              if (teamName.isEmpty || maxMembers < 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ingresa un nombre válido y un número mayor a 0')),
                );
                return;
              }
              setState(() {
                _teams.add(Team(
                  id: _generateId(),
                  name: teamName,
                  maxMembers: maxMembers,
                  members: [],
                  color: _teamColors[_teams.length % _teamColors.length], // Asigna un color cíclicamente
                ));
                _teamNameController.clear();
                _maxMembersController.text = '4';
              });
              Navigator.pop(context);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _addStudentToTeam(String teamId, String studentId) {
    setState(() {
      final team = _teams.firstWhere((t) => t.id == teamId);
      if (team.members.contains(studentId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El alumno ya está en este equipo')),
        );
        return;
      }
      if (team.members.length >= team.maxMembers) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El equipo ${team.name} está lleno')),
        );
        return;
      }
      if (_teams.any((t) => t.members.contains(studentId))) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El alumno ya está asignado a otro equipo')),
        );
        return;
      }
      team.members.add(studentId);
    });
  }

  void _removeStudentFromTeam(String teamId, String studentId) {
    setState(() {
      final team = _teams.firstWhere((t) => t.id == teamId);
      team.members.remove(studentId);
    });
  }

  void _deleteTeam(String teamId) {
    setState(() {
      _teams.removeWhere((t) => t.id == teamId);
    });
  }

  void _showAddStudentDialog(String teamId) {
    final availableStudents = _students.where((s) => !_teams.any((t) => t.members.contains(s.id))).toList();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        title: const Text('Agregar Alumno', style: TextStyle(color: Colors.indigo)),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.4,
          child: availableStudents.isEmpty
              ? const Center(child: Text('No hay alumnos disponibles', style: TextStyle(color: Colors.indigo)))
              : ListView.builder(
                  itemCount: availableStudents.length,
                  itemBuilder: (context, index) {
                    final student = availableStudents[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo[100],
                        child: Text(student.avatar, style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(student.name, style: const TextStyle(color: Colors.indigo)),
                      onTap: () {
                        _addStudentToTeam(teamId, student.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: Colors.indigo)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Equipos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateTeamDialog,
            tooltip: 'Crear nuevo equipo',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alumnos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 2,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3,
                  ),
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    final team = _teams.firstWhere(
                      (t) => t.members.contains(student.id),
                      orElse: () => Team(id: '', name: '', maxMembers: 0, members: [], color: Colors.grey),
                    );
                    final isAssigned = team.id.isNotEmpty;
                    return Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isAssigned ? team.color : Colors.indigo[100],
                              child: Text(
                                student.avatar,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    student.name,
                                    style: const TextStyle(
                                      color: Colors.indigo,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    isAssigned ? 'En ${team.name}' : 'Disponible',
                                    style: TextStyle(
                                      color: isAssigned ? team.color : Colors.green,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Equipos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 3,
                child: _teams.isEmpty
                    ? const Center(child: Text('No hay equipos creados', style: TextStyle(color: Colors.indigo)))
                    : ListView.builder(
                        itemCount: _teams.length,
                        itemBuilder: (context, index) {
                          final team = _teams[index];
                          final teamMembers = _students.where((s) => team.members.contains(s.id)).toList();
                          return Card(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: team.color, width: 2),
                            ),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: team.color,
                                child: Text(
                                  '${team.members.length}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                team.name,
                                style: TextStyle(color: team.color, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${team.members.length}/${team.maxMembers} integrantes',
                                style: TextStyle(color: team.color),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteTeam(team.id),
                                tooltip: 'Eliminar equipo',
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (teamMembers.isEmpty)
                                        Text('No hay miembros', style: TextStyle(color: team.color))
                                      else
                                        ...teamMembers.map((student) => ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor: team.color,
                                                child: Text(
                                                  student.avatar,
                                                  style: const TextStyle(color: Colors.white),
                                                ),
                                              ),
                                              title: Text(
                                                student.name,
                                                style: TextStyle(color: team.color),
                                              ),
                                              trailing: IconButton(
                                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                                onPressed: () => _removeStudentFromTeam(team.id, student.id),
                                              ),
                                            )),
                                      if (team.members.length < team.maxMembers)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: team.color),
                                            onPressed: () => _showAddStudentDialog(team.id),
                                            child: Text(
                                              'Agregar alumno (${team.maxMembers - team.members.length} disponibles)',
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Student {
  final String id;
  final String name;
  final String avatar;

  Student({required this.id, required this.name, required this.avatar});
}

class Team {
  final String id;
  final String name;
  final int maxMembers;
  final List<String> members;
  final Color color;

  Team({
    required this.id,
    required this.name,
    required this.maxMembers,
    required this.members,
    required this.color,
  });
}