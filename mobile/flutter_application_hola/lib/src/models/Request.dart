class Request {
  final String id;
  final String reactivoNombre;
  final double cantidad;
  final String unidad;
  final String proyecto;
  final String solicitante; // Nuevo campo
  String estado;
  final DateTime fecha;

  Request({
    required this.id,
    required this.reactivoNombre,
    required this.cantidad,
    required this.unidad,
    required this.proyecto,
    required this.solicitante, // Nuevo campo
    required this.estado,
    required this.fecha,
  });
}