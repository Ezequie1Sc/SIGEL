class Env {
  static const String appName = 'SIGEL Mobile';
  static const String apiBaseUrl = 'http://localhost:5000';  // Desarrollo
  // static const String apiBaseUrl = 'https://api.tudominio.com';  // Producción
  static const int apiTimeout = 30000; // 30 segundos
  
  // Configuración de uploads
  static const List<String> allowedFileExtensions = ['.pdf', '.doc', '.docx', '.jpg', '.jpeg', '.png'];
  static const int maxFileSize = 16 * 1024 * 1024; // 16MB
}