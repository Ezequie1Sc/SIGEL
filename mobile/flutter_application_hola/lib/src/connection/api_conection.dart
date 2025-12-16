class ApiConnection {
  static const String baseUrl = 'https://api-sigel.inmerso.io';

  // --- Endpoints ---
  static const String tareas = '/tareas';
  static const String entregas = '/entregas';
  static const String avisos = '/avisos';
  static const String download = '/download';
  static const String reactivos = '/reactivos';
  static const String categorias = '/categorias';
  static const String login = '/login';

  // OJO: usuarios SÍ lleva slash final
  static const String usuarios = '/usuarios/';

  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
  };

  // ---- TAREAS ----
  static String getTareasEndpoint() => '$baseUrl$tareas';
  static String getTareaByIdEndpoint(int id) => '$baseUrl$tareas/$id';
  static String getEntregasByTaskEndpoint(int taskId) =>
      '$baseUrl$tareas/$taskId/entregas';

  // ---- ENTREGAS ----
  static String getEntregasEndpoint() => '$baseUrl$entregas';
  static String getEntregaByIdEndpoint(int id) =>
      '$baseUrl$entregas/$id';

  // ---- AVISOS ----
  static String getAvisosEndpoint() => '$baseUrl$avisos';
  static String getAvisoByIdEndpoint(int id) =>
      '$baseUrl$avisos/$id';

  // ---- USUARIOS (FIX 308) ----
  static String getUsuariosEndpoint() => '$baseUrl$usuarios';
  static String getUsuarioByIdEndpoint(int id) =>
      '$baseUrl$usuarios$id';

  // ---- AUTH ----
  static String getLoginEndpoint() => '$baseUrl$login';

  // ---- DESCARGA ----
  static String getDownloadEndpoint() => '$baseUrl$download';

  // ---- REACTIVOS ----
  static String getReactivosEndpoint() => '$baseUrl$reactivos';
  static String getReactivoByIdEndpoint(int id) =>
      '$baseUrl$reactivos/$id';

  // ---- CATEGORIAS ----
  static String getCategoriasEndpoint() => '$baseUrl$categorias';
  static String getCategoriaByIdEndpoint(int id) =>
      '$baseUrl$categorias/$id';

  // ---- MISC ----
  static String getHealthCheckEndpoint() =>
      '$baseUrl/healthcheck';
}
