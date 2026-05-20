k
## 📱 SIGEL Mobile App

Aplicación móvil desarrollada en Flutter para gestión de inventarios, tareas y control de laboratorio.

![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=apple&logoColor=white)


## 🚀 Tecnologías
Flutter 3.x - Framework de desarrollo móvil

- Dart - Lenguaje de programación 
- Flask REST API - Backend y servicios
- PostgreSQL - Base de datos
- HTTP - Cliente para APIs REST
- Shared Preferences - Almacenamiento local
- File Picker - Gestión de archivos
- FL Chart & Syncfusion - Gráficas y visualizaciones
- Table Calendar - Calendario interactivo

 ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Flask API](https://img.shields.io/badge/Flask_API-000000?style=for-the-badge&logo=flask&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-336791?style=for-the-badge&logo=postgresql&logoColor=white)

## 📦 Dependencias del Proyecto
- dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2                    # Iconos iOS
  intl: ^0.20.2                              # Internacionalización y formatos
  fl_chart: ^0.70.2                          # Gráficas interactivas
  syncfusion_flutter_charts: ^29.1.33        # Librería de gráficas profesional
  table_calendar: ^3.0.9                     # Calendario interactivo
  http: ^1.2.2                               # Cliente HTTP para APIs
  shared_preferences: ^2.2.2                 # Almacenamiento local
  file_picker: ^8.3.2                        # Selección de archivos
  path_provider: ^2.1.3                      # Rutas del sistema de archivos
  open_file: ^3.3.2                          # Abrir archivos externamente
  flutter_launcher_icons: ^0.14.4            # Generador de iconos de app

- dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0                      # Análisis de código y mejores prácticas

## 📂 Arquitectura
Clean Architecture Lite (presentación / dominio / datos)

## ✨ Características
- Registro e inicio de sesión
- Vista de docente
- Vista de estudiante
- Gestión de reactivos
- Historial y reportes

## Roles y Funcionalidades
🔧 Vista de Administrador
- Gestión completa de usuarios
- Control total de inventarios
- Configuración del sistema

## 👨‍🏫 Vista de Docente
- Crear y asignar tareas
- Gestionar reactivos del laboratorio
- Revisar y calificar entregas
- Publicar avisos

## 👨‍🎓 Vista de Estudiante
- Ver tareas asignadas
- Entregar tareas con archivos
- Solicitar reactivos para proyectos
- Consultar inventario disponible
- Ver calificaciones y observaciones


## 📚 Sistema de Tareas
- Creación de tareas con fechas límite
- Entrega de archivos (PDF, DOC, imágenes)
- Sistema de calificaciones
- Observaciones y retroalimentación

## 🔐 Autenticación y Seguridad
- Login seguro con roles
- Control de acceso por permisos

## 📱 Interfaz de Usuario
- Navegación intuitiva
- Responsive y adaptativa

------------------------------------------------------------------------------------------------------------------------------------------
## -----Prerrequisitos----------------

# Verificar instalación de Flutter
flutter doctor

# Versión requerida
flutter --version  # >= 3.0.0

# 1. Clonar el repositorio
git clone [url-del-repositorio]
cd mobile.

# 2. Instalar dependencias
flutter pub get

# 3. Configurar variables de entorno
# Crear archivo: lib/core/config/env.dart

# 4. Ejecutar en dispositivo conectado o emulador
flutter run

# Para desarrollo web
flutter run -d chrome

------------------------------------------------------------------------------------------------------------------------------------------
## 🏁 Cómo correr el proyecto desde cable 
flutter pub get
flutter run


## Configuración de Entorno
- Crear lib/src/connection/env.dart:

class Env {
  static const String appName = 'SIGEL Mobile';
  static const String apiBaseUrl = 'http://localhost:5000';  // Desarrollo
  // static const String apiBaseUrl = 'https://api.tudominio.com';  // Producción
  static const int apiTimeout = 30000; // 30 segundos
  
  // Configuración de uploads
  static const List<String> allowedFileExtensions = ['.pdf', '.doc', '.docx', '.jpg', '.jpeg', '.png'];
  static const int maxFileSize = 16 * 1024 * 1024; // 16MB
}

## Comandos de Build
# Build para Android
flutter build apk --release

# Build para Android (App Bundle)
flutter build appbundle --release

# Build para iOS
flutter build ios --release

# Build para Web
flutter build web --release

## 🚀 Variables de API
La aplicación espera los siguientes endpoints:
- Endpoints principales
const apiEndpoints = {
 - 'login': '/login',
  'usuarios': '/usuarios',
  'reactivos': '/reactivos', 
  'solicitudes': '/solicitudes',
  'tareas': '/tareas',
  'entregas': '/entregas',
  'avisos': '/avisos',
  'categorias': '/categorias',
};
## 📂 Estructura de Respuesta Esperada
- {
  "success": true,
  "data": {},
  "message": "Operación exitosa"
}

# 🧪 Testing
# Ejecutar pruebas unitarias
flutter test

# Ejecutar pruebas de integración
flutter test integration_test/

# Generar cobertura de código
flutter test --coverage

## Troubleshooting Común
## Problemas con Dependencias

# Limpiar y reinstalar
flutter clean
flutter pub get

# Si hay conflictos de versiones
flutter pub deps

Problemas con Iconos
bash
# Regenerar iconos
flutter pub run flutter_launcher_icons:main

# Limpiar build
flutter clean
Problemas de Permisos en Android
bash
# En android/app/src/main/AndroidManifest.xml agregar:
<application
    android:usesCleartextTraffic="true"
    ...>
