// En lib/src/models/tarea_model.dart
class Tarea {
  final int id;
  final String titulo;
  final String? descripcion;
  final DateTime? fechaEntrega;
  final String? horaCierre;
  final int? creadoPor;
  final String? archivoRuta;
  final DateTime fechaCreacion;
  final String? status;
  final List<Entrega>? entregas;

  Tarea({
    required this.id,
    required this.titulo,
    this.descripcion,
    this.fechaEntrega,
    this.horaCierre,
    this.creadoPor,
    this.archivoRuta,
    required this.fechaCreacion,
    this.status,
    this.entregas,
  });

  factory Tarea.fromJson(Map<String, dynamic> json) {
    return Tarea(
      id: json['id'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      fechaEntrega: json['fecha_entrega'] != null 
          ? DateTime.parse(json['fecha_entrega']) 
          : null,
      horaCierre: json['hora_cierre'],
      creadoPor: json['creado_por'],
      archivoRuta: json['archivo_ruta'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      status: json['status'],
      entregas: json['entregas'] != null 
          ? (json['entregas'] as List).map((e) => Entrega.fromJson(e)).toList()
          : null,
    );
  }

  // Añade este método para compatibilidad con el código existente
  bool get isCompleted => status?.toLowerCase() == 'completed';
}

class Entrega {
  final int id;
  final int idTarea;
  final int idAlumno;
  final String? archivoRuta;
  final DateTime fechaEntrega;
  final double? calificacion;
  final String? observaciones;
  final Map<String, dynamic>? alumno;

  Entrega({
    required this.id,
    required this.idTarea,
    required this.idAlumno,
    this.archivoRuta,
    required this.fechaEntrega,
    this.calificacion,
    this.observaciones,
    this.alumno,
  });

  factory Entrega.fromJson(Map<String, dynamic> json) {
    return Entrega(
      id: json['id'],
      idTarea: json['id_tarea'],
      idAlumno: json['id_alumno'],
      archivoRuta: json['archivo_ruta'],
      fechaEntrega: DateTime.parse(json['fecha_entrega']),
      calificacion: json['calificacion']?.toDouble(),
      observaciones: json['observaciones'],
      alumno: json['alumno'],
    );
  }

  String get nombreAlumno {
    return alumno != null 
        ? '${alumno!['nombre']} ${alumno!['apellido']}'
        : 'Alumno desconocido';
  }
}