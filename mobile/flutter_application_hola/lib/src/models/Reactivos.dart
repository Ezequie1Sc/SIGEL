class Reactivo {
  final int idReactivo; // Add ID field
  final String nombre;
  final double cantidad;
  final String unidad;
  final double minimo;
  final String categoria;
  final String ubicacion;

  const Reactivo({
    required this.idReactivo,
    required this.nombre,
    required this.cantidad,
    required this.unidad,
    required this.minimo,
    required this.categoria,
    required this.ubicacion,
  });

  factory Reactivo.fromJson(Map<String, dynamic> json) {
    return Reactivo(
      idReactivo: json['id_reactivo'],
      nombre: json['nombre'],
      cantidad: (json['cantidad'] as num).toDouble(),
      unidad: json['unidad'],
      minimo: (json['minimo'] as num).toDouble(),
      categoria: json['categoria']['nombre'],
      ubicacion: json['ubicacion'],
    );
  }
}


class Solicitud {
  final int idReactivo;
  final double cantidad;
  final String proyecto;
  final bool esProyecto;
  final int idUsuario;

  Solicitud({
    required this.idReactivo,
    required this.cantidad,
    required this.proyecto,
    required this.esProyecto,
    required this.idUsuario,
  });

  Map<String, dynamic> toJson() {
    return {
      'id_reactivo': idReactivo,
      'cantidad': cantidad,
      'proyecto': proyecto,
      'es_proyecto': esProyecto,
      'id_usuario': idUsuario,
    };
  }
}