// api_connection.dart - VERSIÓN COMPLETA ACTUALIZADA
class ApiConnection {
  static const String baseUrl = 'http://192.168.1.107:5000';
  
  
  // Endpoints
  static const String tareas = '/tareas';
  static const String entregas = '/entregas';
  static const String avisos = '/avisos';
  static const String download = '/download';
  static const String usuarios = '/usuarios';
  static const String login = '/login';
  static const String reactivos = '/reactivos';
  static const String categorias = '/categorias';
  
  // Headers
  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
  };
  
  // Métodos auxiliares para construir URLs completas
  
  // Tareas
  static String getTareasEndpoint() => baseUrl + tareas;
  static String getTareaByIdEndpoint(int id) => '${baseUrl + tareas}/$id';
  static String getEntregasEndpoint() => baseUrl + entregas;
  static String getEntregaByIdEndpoint(int id) => '${baseUrl + entregas}/$id';
  static String getAvisosEndpoint() => baseUrl + avisos;
  static String getAvisoByIdEndpoint(int id) => '${baseUrl + avisos}/$id';
  static String getDownloadEndpoint() => baseUrl + download;
  static String getEntregasByTaskEndpoint(int taskId) => '${baseUrl + tareas}/$taskId/entregas';
  
  // Usuarios
  static String getUsuariosEndpoint() => baseUrl + usuarios;
  static String getUsuarioByIdEndpoint(int id) => '${baseUrl + usuarios}/$id';
  static String getLoginEndpoint() => baseUrl + login;
  
  // Reactivos y Categorías
  static String getReactivosEndpoint() => baseUrl + reactivos;
  static String getReactivoByIdEndpoint(int id) => '${baseUrl + reactivos}/$id';
  static String getCategoriasEndpoint() => baseUrl + categorias;
  static String getCategoriaByIdEndpoint(int id) => '${baseUrl + categorias}/$id';
  
  // Método para verificar la conexión
  static String getCurrentBaseUrl() => baseUrl;
  
  // Método para obtener URL de healthcheck
  static String getHealthCheckEndpoint() => '$baseUrl/healthcheck';
}