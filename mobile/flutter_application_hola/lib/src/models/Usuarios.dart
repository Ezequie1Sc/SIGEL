class Usuario {
  final int? idUsuario;
  final String username;
  final String nombre;
  final String apellido;
  final String email;
  final String rol;

  Usuario({
    this.idUsuario,
    required this.username,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['id_usuario'],
      username: json['username'],
      nombre: json['nombre'],
      apellido: json['apellido'],
      email: json['email'],
      rol: json['rol'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'rol': rol,
    };
  }
}