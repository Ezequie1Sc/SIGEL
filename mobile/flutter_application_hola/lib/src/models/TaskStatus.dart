// task_model.dart
import 'package:intl/intl.dart';

enum TaskStatus { pending, delivered }

class Task {
  final int id;
  final String title;
  final String creator;
  final DateTime dueDate;
  final String? dueTime;
  final String? description;
  final TaskStatus status;
  final List<Map<String, dynamic>> deliveries;
  final String? filePath;
  final int? creatorId;

  Task({
    required this.id,
    required this.title,
    required this.creator,
    required this.dueDate,
    this.dueTime,
    this.description,
    required this.status,
    required this.deliveries,
    this.filePath,
    this.creatorId,
  });

  factory Task.fromApi(Map<String, dynamic> data) {
    return Task(
      id: data['id'] ?? 0,
      title: data['title'] ?? 'Sin título',
      creator: data['creator'] ?? 'Desconocido',
      creatorId: data['creator_id'],
      dueDate: DateTime.parse(data['due_date'] ?? DateTime.now().toString()),
      dueTime: data['due_time']?.toString(),
      description: data['description'],
      status: (data['status']?.toString().toLowerCase() == 'entregado' ||
              data['status']?.toString().toLowerCase() == 'delivered')
          ? TaskStatus.delivered
          : TaskStatus.pending,
      deliveries: data['deliveries'] != null
          ? List<Map<String, dynamic>>.from(data['deliveries'])
          : [],
      filePath: data['archivo_ruta'], // Cambiado de file_path a archivo_ruta para coincidir con API
    );
  }

  String get formattedDueDate {
    return DateFormat('dd/MM/yyyy').format(dueDate);
  }

  String get formattedDueDateTime {
    if (dueTime != null && dueTime!.isNotEmpty) {
      try {
        final timeParts = dueTime!.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final dateTime = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          hour,
          minute,
        );
        return DateFormat('dd MMMM yyyy - hh:mm a').format(dateTime);
      } catch (e) {
        return DateFormat('dd MMMM yyyy').format(dueDate);
      }
    }
    return DateFormat('dd MMMM yyyy').format(dueDate);
  }

  bool get isExpired {
    final now = DateTime.now();
    if (dueTime != null && dueTime!.isNotEmpty) {
      try {
        final timeParts = dueTime!.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        final dueDateTime = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          hour,
          minute,
        );
        return now.isAfter(dueDateTime);
      } catch (e) {
        return now.isAfter(dueDate.add(const Duration(hours: 23, minutes: 59)));
      }
    }
    return now.isAfter(dueDate.add(const Duration(hours: 23, minutes: 59)));
  }

  String calculateRemainingTime() {
    final now = DateTime.now();
    DateTime dueDateTime = dueDate;

    if (dueTime != null && dueTime!.isNotEmpty) {
      try {
        final timeParts = dueTime!.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        dueDateTime = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          hour,
          minute,
        );
      } catch (e) {
        dueDateTime = dueDate.add(const Duration(hours: 23, minutes: 59));
      }
    }

    final difference = dueDateTime.difference(now);

    if (difference.isNegative) {
      return 'Tiempo expirado';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} días ${difference.inHours.remainder(24)} horas';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} horas ${difference.inMinutes.remainder(60)} minutos';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutos';
    } else {
      return 'Menos de 1 minuto';
    }
  }
}

class TaskGroup {
  final DateTime date;
  final List<Task> tasks;

  TaskGroup({required this.date, required this.tasks});
}