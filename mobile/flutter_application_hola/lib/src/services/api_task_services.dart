import 'dart:convert';
import 'package:flutter_application_hola/src/connection/api_conection.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ApiTaskServices {
 
  dynamic _handleResponse(http.Response response) {
    print('=== API Response ===');
    print('Status Code: ${response.statusCode}');
    print('Body: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}');
    print('Headers: ${response.headers}');
   
    // Intentar parsear JSON
    try {
      if (response.body.isNotEmpty) {
        final decoded = json.decode(response.body);
        return decoded;
      }
      return null;
    } catch (e) {
      print('Failed to parse JSON: $e');
      // Si no es JSON válido, devolver el body como texto
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      } else {
        throw Exception(
          'Error en la petición: ${response.statusCode} - ${response.body}',
        );
      }
    }
  }

  Future<List<dynamic>> getAllTasks() async {
    try {
      print('Fetching all tasks...');
      final response = await http.get(
        Uri.parse(ApiConnection.getTareasEndpoint()),
        headers: ApiConnection.jsonHeaders,
      );
      final result = _handleResponse(response);
      return result is List ? result : [];
    } catch (e) {
      print('Error en getAllTasks: $e');
      return [];
    }
  }

  Future<dynamic> getTaskById(int taskId) async {
    try {
      print('Fetching task by ID: $taskId');
      final response = await http.get(
        Uri.parse(ApiConnection.getTareaByIdEndpoint(taskId)),
        headers: ApiConnection.jsonHeaders,
      );
      return _handleResponse(response);
    } catch (e) {
      print('Error en getTaskById: $e');
      rethrow;
    }
  }

  Future<dynamic> createTask({
    required String titulo,
    String? descripcion,
    String? fechaEntrega,
    String? horaCierre,
    required int creadoPor,
    File? archivo,
  }) async {
    try {
      print('Creating task: $titulo');
      var uri = Uri.parse(ApiConnection.getTareasEndpoint());
      const int maxRedirects = 5;
      int redirectCount = 0;
      while (redirectCount < maxRedirects) {
        var request = http.MultipartRequest('POST', uri);
        request.fields['titulo'] = titulo;
        request.fields['creado_por'] = creadoPor.toString();
        if (descripcion != null) request.fields['descripcion'] = descripcion;
        if (fechaEntrega != null) request.fields['fecha_entrega'] = fechaEntrega;
        if (horaCierre != null) request.fields['hora_cierre'] = horaCierre;
        if (archivo != null) {
          print('Attaching file: ${archivo.path}');
          var fileStream = http.ByteStream(archivo.openRead());
          var length = await archivo.length();
          var multipartFile = http.MultipartFile(
            'file',
            fileStream,
            length,
            filename: archivo.path.split('/').last,
            contentType: MediaType('application', 'octet-stream'),
          );
          request.files.add(multipartFile);
        }
        var response = await request.send();
        var responseBody = await response.stream.bytesToString();
        print('Create task response: ${response.statusCode}');
        print('Response body: $responseBody');
        if (response.statusCode >= 200 && response.statusCode < 300) {
          try {
            return responseBody.isNotEmpty ? json.decode(responseBody) : {
              'id': DateTime.now().millisecondsSinceEpoch,
              'titulo': titulo,
              'creado_por': creadoPor
            };
          } catch (e) {
            return {
              'id': DateTime.now().millisecondsSinceEpoch,
              'titulo': titulo,
              'creado_por': creadoPor
            };
          }
        } else if (response.statusCode == 308) {
          final redirectUrl = response.headers['location'];
          if (redirectUrl == null) {
            throw Exception('Error 308 sin URL de redirección: $responseBody');
          }
          uri = Uri.parse(redirectUrl);
          redirectCount++;
          print('Redirecting to: $uri (intento ${redirectCount + 1})');
          continue;
        } else {
          throw Exception('Error al crear tarea: ${response.statusCode} - $responseBody');
        }
      }
      throw Exception('Demasiadas redirecciones ($maxRedirects) al crear tarea');
    } catch (e) {
      print('Error en createTask: $e');
      rethrow;
    }
  }

  Future<dynamic> updateTask({
    required int taskId,
    required String titulo,
    String? descripcion,
    String? fechaEntrega,
    String? horaCierre,
    File? archivo,
  }) async {
    try {
      print('Updating task ID: $taskId');
      var uri = Uri.parse(ApiConnection.getTareaByIdEndpoint(taskId));
      const int maxRedirects = 5;
      int redirectCount = 0;
      while (redirectCount < maxRedirects) {
        var request = http.MultipartRequest('PUT', uri);
        request.fields['titulo'] = titulo;
        if (descripcion != null) request.fields['descripcion'] = descripcion;
        if (fechaEntrega != null) request.fields['fecha_entrega'] = fechaEntrega;
        if (horaCierre != null) request.fields['hora_cierre'] = horaCierre;
        if (archivo != null) {
          print('Attaching file for update: ${archivo.path}');
          var fileStream = http.ByteStream(archivo.openRead());
          var length = await archivo.length();
          var multipartFile = http.MultipartFile(
            'file',
            fileStream,
            length,
            filename: archivo.path.split('/').last,
            contentType: MediaType('application', 'octet-stream'),
          );
          request.files.add(multipartFile);
        }
        var response = await request.send();
        var responseBody = await response.stream.bytesToString();
        print('Update task response: ${response.statusCode}');
        print('Response body: $responseBody');
        if (response.statusCode >= 200 && response.statusCode < 300) {
          try {
            return responseBody.isNotEmpty ? json.decode(responseBody) : {
              'id': taskId,
              'titulo': titulo,
              'updated': true
            };
          } catch (e) {
            return {
              'id': taskId,
              'titulo': titulo,
              'updated': true
            };
          }
        } else if (response.statusCode == 308) {
          final redirectUrl = response.headers['location'];
          if (redirectUrl == null) {
            throw Exception('Error 308 sin URL de redirección: $responseBody');
          }
          uri = Uri.parse(redirectUrl);
          redirectCount++;
          print('Redirecting to: $uri (intento ${redirectCount + 1})');
          continue;
        } else {
          throw Exception('Error al actualizar tarea: ${response.statusCode} - $responseBody');
        }
      }
      throw Exception('Demasiadas redirecciones ($maxRedirects) al actualizar tarea');
    } catch (e) {
      print('Error en updateTask: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(int taskId) async {
    try {
      print('Deleting task ID: $taskId');
      final response = await http.delete(
        Uri.parse(ApiConnection.getTareaByIdEndpoint(taskId)),
        headers: ApiConnection.jsonHeaders,
      );
      _handleResponse(response);
      print('Task deleted successfully');
    } catch (e) {
      print('Error en deleteTask: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getDeliveriesByTask(int taskId) async {
    try {
      print('Fetching deliveries for task ID: $taskId');
      final response = await http.get(
        Uri.parse(ApiConnection.getEntregasByTaskEndpoint(taskId)),
        headers: ApiConnection.jsonHeaders,
      );
     
      print('Deliveries response status: ${response.statusCode}');
      final result = _handleResponse(response);
     
      if (result is List) {
        print('Found ${result.length} deliveries');
        return result;
      } else if (result is Map && result.containsKey('entregas')) {
        print('Found deliveries in entregas key');
        return result['entregas'] is List ? result['entregas'] : [];
      } else {
        print('No deliveries found or invalid format');
        return [];
      }
    } catch (e) {
      print('Error en getDeliveriesByTask: $e');
      return [];
    }
  }

  Future<dynamic> createDelivery({
    required int taskId,
    required int alumnoId,
    File? archivo,
    double? calificacion,
    String? observaciones,
  }) async {
    try {
      print('Creating delivery for task: $taskId, student: $alumnoId');
      var uri = Uri.parse(ApiConnection.getEntregasEndpoint());
      const int maxRedirects = 5;
      int redirectCount = 0;
      while (redirectCount < maxRedirects) {
        var request = http.MultipartRequest('POST', uri);
        request.fields['id_tarea'] = taskId.toString();
        request.fields['id_alumno'] = alumnoId.toString();
        if (calificacion != null) request.fields['calificacion'] = calificacion.toString();
        if (observaciones != null) request.fields['observaciones'] = observaciones;
        if (archivo != null) {
          print('Attaching delivery file: ${archivo.path}');
          var fileStream = http.ByteStream(archivo.openRead());
          var length = await archivo.length();
          var multipartFile = http.MultipartFile(
            'file',
            fileStream,
            length,
            filename: archivo.path.split('/').last,
            contentType: MediaType('application', 'octet-stream'),
          );
          request.files.add(multipartFile);
        }
        var response = await request.send();
        var responseBody = await response.stream.bytesToString();
        print('Create delivery response: ${response.statusCode}');
        print('Response body: $responseBody');
        if (response.statusCode >= 200 && response.statusCode < 300) {
          try {
            final result = responseBody.isNotEmpty ? json.decode(responseBody) : {
              'id': DateTime.now().millisecondsSinceEpoch,
              'id_tarea': taskId,
              'id_alumno': alumnoId,
              'created': true
            };
            print('Delivery created successfully: $result');
            return result;
          } catch (e) {
            final result = {
              'id': DateTime.now().millisecondsSinceEpoch,
              'id_tarea': taskId,
              'id_alumno': alumnoId,
              'created': true
            };
            print('Delivery created (fallback): $result');
            return result;
          }
        } else if (response.statusCode == 308) {
          final redirectUrl = response.headers['location'];
          if (redirectUrl == null) {
            throw Exception('Error 308 sin URL de redirección: $responseBody');
          }
          uri = Uri.parse(redirectUrl);
          redirectCount++;
          print('Redirecting to: $uri (intento ${redirectCount + 1})');
          continue;
        } else {
          throw Exception('Error al crear entrega: ${response.statusCode} - $responseBody');
        }
      }
      throw Exception('Demasiadas redirecciones ($maxRedirects) al crear entrega');
    } catch (e) {
      print('Error en createDelivery: $e');
      rethrow;
    }
  }

  Future<dynamic> updateDelivery({
    required int deliveryId,
    File? archivo,
    double? calificacion,
    String? observaciones,
  }) async {
    try {
      print('Updating delivery ID: $deliveryId');
      var uri = Uri.parse(ApiConnection.getEntregaByIdEndpoint(deliveryId));
      const int maxRedirects = 5;
      int redirectCount = 0;
      while (redirectCount < maxRedirects) {
        var request = http.MultipartRequest('PUT', uri);
        if (calificacion != null) request.fields['calificacion'] = calificacion.toString();
        if (observaciones != null) request.fields['observaciones'] = observaciones;
        if (archivo != null) {
          print('Attaching updated file: ${archivo.path}');
          var fileStream = http.ByteStream(archivo.openRead());
          var length = await archivo.length();
          var multipartFile = http.MultipartFile(
            'file',
            fileStream,
            length,
            filename: archivo.path.split('/').last,
            contentType: MediaType('application', 'octet-stream'),
          );
          request.files.add(multipartFile);
        }
        var response = await request.send();
        var responseBody = await response.stream.bytesToString();
        print('Update delivery response: ${response.statusCode}');
        print('Response body: $responseBody');
        if (response.statusCode >= 200 && response.statusCode < 300) {
          try {
            final result = responseBody.isNotEmpty ? json.decode(responseBody) : {
              'id': deliveryId,
              'updated': true,
              'calificacion': calificacion
            };
            print('Delivery updated successfully: $result');
            return result;
          } catch (e) {
            final result = {
              'id': deliveryId,
              'updated': true,
              'calificacion': calificacion
            };
            print('Delivery updated (fallback): $result');
            return result;
          }
        } else if (response.statusCode == 308) {
          final redirectUrl = response.headers['location'];
          if (redirectUrl == null) {
            throw Exception('Error 308 sin URL de redirección: $responseBody');
          }
          uri = Uri.parse(redirectUrl);
          redirectCount++;
          print('Redirecting to: $uri (intento ${redirectCount + 1})');
          continue;
        } else {
          throw Exception('Error al actualizar entrega: ${response.statusCode} - $responseBody');
        }
      }
      throw Exception('Demasiadas redirecciones ($maxRedirects) al actualizar entrega');
    } catch (e) {
      print('Error en updateDelivery: $e');
      rethrow;
    }
  }

  Future<void> deleteDelivery(int deliveryId) async {
    try {
      print('Deleting delivery ID: $deliveryId');
      final response = await http.delete(
        Uri.parse(ApiConnection.getEntregaByIdEndpoint(deliveryId)),
        headers: ApiConnection.jsonHeaders,
      );
      _handleResponse(response);
      print('Delivery deleted successfully');
    } catch (e) {
      print('Error en deleteDelivery: $e');
      rethrow;
    }
  }

  // MÉTODO DOWNLOADFILE CORREGIDO - SOLUCIÓN SIMPLIFICADA
  Future<File?> downloadFile({
    required String resourceType,
    required int resourceId,
    required String filePath,
  }) async {
    try {
      print('=== DOWNLOAD FILE START ===');
      print('Resource Type: $resourceType');
      print('Resource ID: $resourceId');
      print('Original File Path: $filePath');

      // Validar filePath
      if (filePath.isEmpty || filePath == 'Sin archivo' || filePath == 'null') {
        throw Exception('No hay archivo disponible para descargar');
      }

      // Decodificar caracteres especiales si es necesario
      filePath = Uri.decodeFull(filePath);
      
      // Extraer el nombre del archivo del path
      String fileName = filePath.split('/').last;
      if (fileName.isEmpty) {
        fileName = 'archivo_${resourceType}_${resourceId}_${DateTime.now().millisecondsSinceEpoch}';
      }
      
      print('File Name: $fileName');

      // Construir la URL completa usando la ruta real del archivo
      // IMPORTANTE: Usar la baseUrl + archivo_ruta directamente
      final baseUrl = ApiConnection.baseUrl;
      
      // Asegurar que la ruta comience con /
      String cleanFilePath = filePath;
      if (!cleanFilePath.startsWith('/')) {
        cleanFilePath = '/$cleanFilePath';
      }
      
      // Construir URL completa
      final String fileUrl = baseUrl + cleanFilePath;
      print('Download URL: $fileUrl');

      // Crear directorio de descarga
      final directory = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${directory.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
        print('Created download directory: ${downloadDir.path}');
      }

      // Sanitizar el nombre del archivo
      String safeFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      if (safeFileName.isEmpty) {
        safeFileName = 'archivo_${resourceType}_${resourceId}_${DateTime.now().millisecondsSinceEpoch}';
      }
      
      final filePathLocal = '${downloadDir.path}/$safeFileName';
      print('Local Path: $filePathLocal');

      // Verificar si el archivo ya existe localmente
      final localFile = File(filePathLocal);
      if (await localFile.exists()) {
        final fileSize = await localFile.length();
        if (fileSize > 0) {
          print('✅ File already exists locally: ${localFile.path} (${fileSize} bytes)');
          return localFile;
        } else {
          print('⚠️ Local file exists but is empty, re-downloading...');
          await localFile.delete();
        }
      }

      // REALIZAR LA DESCARGA CON LOS HEADERS CORRECTOS
      print('Starting download from: $fileUrl');
      
      // IMPORTANTE: NO usar headers JSON para archivos binarios
      // Solo usar Accept: */* y Authorization si es necesario
      final Map<String, String> headers = {
        'Accept': '*/*',  // Aceptar cualquier tipo de contenido
      };
      
      // Agregar Authorization solo si está disponible en ApiConnection.jsonHeaders
      if (ApiConnection.jsonHeaders.containsKey('Authorization')) {
        headers['Authorization'] = ApiConnection.jsonHeaders['Authorization']!;
      }
      
      print('Using headers: $headers');
      
      final response = await http.get(
        Uri.parse(fileUrl),
        headers: headers,
      );

      print('Response Status: ${response.statusCode}');
      print('Content-Type: ${response.headers['content-type']}');
      print('Content-Length: ${response.headers['content-length']}');

      if (response.statusCode == 200) {
        // VERIFICAR que response.bodyBytes no esté vacío
        if (response.bodyBytes.isEmpty) {
          throw Exception('El archivo está vacío o no se pudo descargar');
        }
        
        final fileSize = response.bodyBytes.length;
        print('File size from response: $fileSize bytes');
        
        // Guardar el archivo
        await localFile.writeAsBytes(response.bodyBytes);
        final savedFileSize = await localFile.length();
        
        if (savedFileSize > 0) {
          print('✅ File downloaded successfully!');
          print(' Local Path: ${localFile.path}');
          print(' Saved Size: $savedFileSize bytes');
          return localFile;
        } else {
          throw Exception('Error al guardar el archivo localmente (tamaño 0)');
        }
      } else if (response.statusCode == 404) {
        throw Exception('El archivo no se encuentra en el servidor (Error 404)');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos para acceder a este archivo');
      } else {
        throw Exception('Error del servidor: ${response.statusCode} - ${response.body}');
      }
      
    } catch (e) {
      print('❌ Error en downloadFile: $e');
      print('Stack trace: ${e.toString()}');
      
      // Propagar el error con un mensaje más claro
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup')) {
        throw Exception('No se pudo conectar al servidor. Verifica tu conexión a internet.');
      } else if (e.toString().contains('404')) {
        throw Exception('El archivo no existe en el servidor.');
      } else if (e.toString().contains('403')) {
        throw Exception('No tienes permisos para descargar este archivo.');
      } else {
        rethrow;
      }
    }
  }

  // Método para verificar si un archivo existe en el servidor (simple)
  Future<bool> checkFileExists(String filePath) async {
    try {
      final baseUrl = ApiConnection.baseUrl;
      
      // Asegurar que la ruta comience con /
      String cleanFilePath = filePath;
      if (!cleanFilePath.startsWith('/')) {
        cleanFilePath = '/$cleanFilePath';
      }
      
      final String fileUrl = baseUrl + cleanFilePath;
      print('Checking file existence at: $fileUrl');
      
      final response = await http.head(
        Uri.parse(fileUrl),
        headers: {'Accept': '*/*'},
      );
      
      print('File check status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error checking file existence: $e');
      return false;
    }
  }
  
  Future<List<dynamic>> getTasksByUser(int userId) async {
    try {
      print('Fetching tasks for user ID: $userId');
      final response = await http.get(
        Uri.parse('${ApiConnection.getTareasEndpoint()}?user_id=$userId'),
        headers: ApiConnection.jsonHeaders,
      );
      
      print('Tasks by user response status: ${response.statusCode}');
      final result = _handleResponse(response);
      
      if (result is List) {
        print('Found ${result.length} tasks for user $userId');
        return result;
      } else if (result is Map && result.containsKey('tareas')) {
        print('Found tasks in tareas key');
        return result['tareas'] is List ? result['tareas'] : [];
      } else if (result is Map && result.containsKey('data')) {
        print('Found tasks in data key');
        return result['data'] is List ? result['data'] : [];
      } else {
        print('No tasks found or invalid format');
        return [];
      }
    } catch (e) {
      print('Error en getTasksByUser: $e');
      throw Exception('Error al obtener tareas del usuario: $e');
    }
  }
  
  Future<List<dynamic>> getPendingTasks(int alumnoId) async {
    try {
      print('Fetching pending tasks for student: $alumnoId');
      final tasks = await getTasksByUser(alumnoId);
      final pendingTasks = tasks.where((task) {
        final status = task['status']?.toString().toLowerCase();
        final entregas = task['entregas'] ?? [];
        final userDelivery = entregas.firstWhere(
          (entrega) => (entrega['id_alumno'] ?? entrega['alumno_id']) == alumnoId,
          orElse: () => null,
        );
        
        // Si no tiene entrega o está pendiente
        return userDelivery == null || (status == 'pending' || status == 'pendiente');
      }).toList();
      
      print('Found ${pendingTasks.length} pending tasks');
      return pendingTasks;
    } catch (e) {
      print('Error en getPendingTasks: $e');
      throw Exception('Error al obtener tareas pendientes: $e');
    }
  }
  
  Future<List<dynamic>> getUpcomingTasks({int? userId}) async {
    try {
      print('Fetching upcoming tasks${userId != null ? ' for user: $userId' : ''}');
      final now = DateTime.now();
      final response = await http.get(
        Uri.parse(userId != null
            ? '${ApiConnection.getTareasEndpoint()}?user_id=$userId'
            : ApiConnection.getTareasEndpoint()),
        headers: ApiConnection.jsonHeaders,
      );
      
      final result = _handleResponse(response);
      final allTasks = result is List ? result : [];
      final upcomingTasks = allTasks.where((task) {
        if (task['fecha_entrega'] == null) return false;
        try {
          final fechaEntrega = DateTime.parse(task['fecha_entrega'].toString());
          final isUpcoming = fechaEntrega.isAfter(now) ||
              (fechaEntrega.year == now.year &&
                  fechaEntrega.month == now.month &&
                  fechaEntrega.day == now.day);
          return isUpcoming;
        } catch (e) {
          return false;
        }
      }).toList();
      print('Found ${upcomingTasks.length} upcoming tasks');
      return upcomingTasks;
    } catch (e) {
      print('Error en getUpcomingTasks: $e');
      throw Exception('Error al obtener tareas próximas: $e');
    }
  }
  
  Future<List<Map<String, dynamic>>> displayTasks({
    required int userId,
    String? userRole,
  }) async {
    try {
      print('\n=== DISPLAY TASKS START ===');
      print('User ID: $userId, Role: $userRole');
      
      final tasks = await getTasksByUser(userId);
      print('Raw tasks from API: ${tasks.length}');
      
      final formattedTasks = <Map<String, dynamic>>[];
      for (final task in tasks) {
        print('\n--- Processing Task ---');
        print('ID: ${task['id']}, Title: ${task['titulo']}');
        
        List<Map<String, dynamic>> formattedEntregas = [];
        
        // Solo obtener entregas si hay una tarea válida
        if (task['id'] != null) {
          int taskId;
          try {
            taskId = int.parse(task['id'].toString());
            print('Task ID parsed: $taskId');
          } catch (e) {
            print('❌ Invalid task ID: ${task['id']}');
            continue;
          }
          
          // Obtener entregas de la tarea
          final entregas = await getDeliveriesByTask(taskId);
          print('Found ${entregas.length} deliveries for task $taskId');
          
          if (userRole == 'docente' || userRole == 'admin') {
            // Para profesores, mostrar todas las entregas
            formattedEntregas = entregas.map((entrega) {
              print('Processing delivery: ${entrega['id']}');
              
              // Extraer nombre del alumno
              String alumnoNombre = 'Desconocido';
              if (entrega['alumno'] != null) {
                if (entrega['alumno'] is Map) {
                  final nombre = entrega['alumno']['nombre']?.toString() ?? '';
                  final apellido = entrega['alumno']['apellido']?.toString() ?? '';
                  alumnoNombre = '$nombre $apellido'.trim();
                  if (alumnoNombre.isEmpty) {
                    alumnoNombre = entrega['alumno'].toString();
                  }
                } else {
                  alumnoNombre = entrega['alumno'].toString();
                }
              }
              
              // Extraer calificación
              dynamic calificacion = entrega['calificacion'];
              String calificacionStr = 'Sin calificar';
              if (calificacion != null) {
                if (calificacion is num) {
                  calificacionStr = calificacion.toString();
                } else {
                  calificacionStr = calificacion.toString();
                }
              }
              
              // Extraer fecha de entrega
              String fechaEntregaStr = '';
              if (entrega['fecha_entrega'] != null) {
                try {
                  final fecha = DateTime.parse(entrega['fecha_entrega'].toString());
                  fechaEntregaStr = fecha.toIso8601String();
                } catch (e) {
                  fechaEntregaStr = entrega['fecha_entrega'].toString();
                }
              }
              
              // Extraer ruta del archivo
              String archivoRuta = entrega['archivo_ruta']?.toString() ?? 'Sin archivo';
              print('Delivery file path: $archivoRuta');
              
              final formattedDelivery = {
                'id_entrega': entrega['id'] ?? 0,
                'alumno': alumnoNombre,
                'archivo_ruta': archivoRuta,
                'fecha_entrega': fechaEntregaStr,
                'calificacion': calificacionStr,
                'observaciones': entrega['observaciones']?.toString() ?? 'Sin observaciones',
                'id_alumno': entrega['id_alumno'] ?? entrega['alumno_id'] ?? 0,
                'status': entrega['status']?.toString() ?? 'pending',
              };
              
              print('Formatted delivery: $formattedDelivery');
              return formattedDelivery;
            }).toList();
          } else if (userRole == 'alumno') {
            // Para alumnos, solo sus entregas
            final userDeliveries = entregas.where((entrega) {
              final entregaAlumnoId = entrega['id_alumno'] ?? entrega['alumno_id'];
              final matches = entregaAlumnoId == userId;
              print('Delivery alumno ID: $entregaAlumnoId, matches: $matches');
              return matches;
            }).toList();
            
            print('Found ${userDeliveries.length} deliveries for current student');
            
            formattedEntregas = userDeliveries.map((entrega) {
              print('Processing student delivery: ${entrega['id']}');
              
              // Extraer calificación
              dynamic calificacion = entrega['calificacion'];
              String calificacionStr = 'Sin calificar';
              if (calificacion != null) {
                if (calificacion is num) {
                  calificacionStr = calificacion.toString();
                } else {
                  calificacionStr = calificacion.toString();
                }
              }
              
              // Extraer fecha de entrega
              String fechaEntregaStr = '';
              if (entrega['fecha_entrega'] != null) {
                try {
                  final fecha = DateTime.parse(entrega['fecha_entrega'].toString());
                  fechaEntregaStr = fecha.toIso8601String();
                } catch (e) {
                  fechaEntregaStr = entrega['fecha_entrega'].toString();
                }
              }
              
              // Extraer ruta del archivo
              String archivoRuta = entrega['archivo_ruta']?.toString() ?? 'Sin archivo';
              
              final formattedDelivery = {
                'id_entrega': entrega['id'] ?? 0,
                'alumno': 'Tú',
                'archivo_ruta': archivoRuta,
                'fecha_entrega': fechaEntregaStr,
                'calificacion': calificacionStr,
                'observaciones': entrega['observaciones']?.toString() ?? 'Sin observaciones',
                'id_alumno': entrega['id_alumno'] ?? entrega['alumno_id'] ?? 0,
                'status': entrega['status']?.toString() ?? 'pending',
              };
              
              print('Formatted student delivery: $formattedDelivery');
              return formattedDelivery;
            }).toList();
          }
          
          print('Total formatted deliveries: ${formattedEntregas.length}');
        }
        // Determinar el status de la tarea
        String taskStatus;
        if (userRole == 'alumno') {
          // Para alumnos, el status depende de si tienen entregas
          taskStatus = formattedEntregas.isNotEmpty ? 'delivered' : 'pending';
        } else {
          // Para profesores, usar el status de la tarea o determinar por entregas
          taskStatus = task['status']?.toString().toLowerCase() ??
                      (formattedEntregas.isNotEmpty ? 'delivered' : 'pending');
        }
        // Formatear fecha de entrega
        String fechaEntrega;
        try {
          if (task['fecha_entrega'] != null) {
            final date = DateTime.parse(task['fecha_entrega'].toString());
            fechaEntrega = date.toIso8601String();
          } else {
            fechaEntrega = DateTime.now().add(Duration(days: 7)).toIso8601String();
          }
        } catch (e) {
          print('Error parsing fecha_entrega: $e');
          fechaEntrega = DateTime.now().add(Duration(days: 7)).toIso8601String();
        }
        
        // Formatear hora de cierre
        String horaCierre = task['hora_cierre']?.toString() ?? '23:59';
        
        // Formatear creador
        String creador;
        if (task['creador'] != null) {
          if (task['creador'] is Map) {
            final nombre = task['creador']['nombre']?.toString() ?? '';
            final apellido = task['creador']['apellido']?.toString() ?? '';
            creador = '$nombre $apellido'.trim();
            if (creador.isEmpty) {
              creador = task['creador'].toString();
            }
          } else {
            creador = task['creador'].toString();
          }
        } else {
          creador = 'Desconocido';
        }
        
        // Extraer ID del creador
        int? creadorId;
        if (task['creado_por'] != null) {
          creadorId = int.tryParse(task['creado_por'].toString());
        } else if (task['creador_id'] != null) {
          creadorId = int.tryParse(task['creador_id'].toString());
        }
        
        // Extraer ruta del archivo de la tarea
        String archivoRutaTarea = task['archivo_ruta']?.toString() ?? 'Sin archivo';
        print('Task file path: $archivoRutaTarea');
        final formattedTask = {
          'id': int.parse(task['id']?.toString() ?? '0'),
          'title': task['titulo']?.toString() ?? 'Sin título',
          'description': task['descripcion']?.toString(),
          'due_date': fechaEntrega,
          'due_time': horaCierre,
          'creator': creador,
          'creator_id': creadorId,
          'archivo_ruta': archivoRutaTarea,
          'status': taskStatus,
          'deliveries': formattedEntregas,
        };
        
        formattedTasks.add(formattedTask);
        print('✅ Added formatted task: ${formattedTask['id']} - ${formattedTask['title']}');
      }
      print('\n=== DISPLAY TASKS RESULT ===');
      print('Total formatted tasks: ${formattedTasks.length}');
      for (var task in formattedTasks) {
        print(' Task ${task['id']}: ${task['title']}');
        print(' Status: ${task['status']}');
        print(' Deliveries: ${task['deliveries'].length}');
        print(' File: ${task['archivo_ruta']}');
        if (task['deliveries'].isNotEmpty) {
          print(' First delivery calificacion: ${task['deliveries'][0]['calificacion']}');
          print(' First delivery file: ${task['deliveries'][0]['archivo_ruta']}');
        }
      }
      print('=== DISPLAY TASKS END ===\n');
      
      return formattedTasks;
    } catch (e) {
      print('❌ Error in displayTasks: $e');
      print('Stack trace: ${e.toString()}');
      throw Exception('Error al mostrar tareas: $e');
    }
  }
  
  Future<List<dynamic>> getAllAnnouncements() async {
    try {
      print('Fetching all announcements...');
      final response = await http.get(
        Uri.parse(ApiConnection.getAvisosEndpoint()),
        headers: ApiConnection.jsonHeaders,
      );
      final result = _handleResponse(response);
      return result is List ? result : [];
    } catch (e) {
      print('Error en getAllAnnouncements: $e');
      return [];
    }
  }
  
  Future<dynamic> getAnnouncementById(int announcementId) async {
    try {
      print('Fetching announcement by ID: $announcementId');
      final response = await http.get(
        Uri.parse(ApiConnection.getAvisoByIdEndpoint(announcementId)),
        headers: ApiConnection.jsonHeaders,
      );
      return _handleResponse(response);
    } catch (e) {
      print('Error en getAnnouncementById: $e');
      rethrow;
    }
  }
  
  Future<dynamic> createAnnouncement({
    required int idUsuario,
    required String texto,
    String? titulo,
  }) async {
    try {
      print('Creating announcement: ${titulo ?? "Sin título"}');
      var uri = Uri.parse(ApiConnection.getAvisosEndpoint());
      const int maxRedirects = 5;
      int redirectCount = 0;
      while (redirectCount < maxRedirects) {
        final response = await http.post(
          uri,
          headers: ApiConnection.jsonHeaders,
          body: json.encode({
            'id_usuario': idUsuario,
            'titulo': titulo ?? 'Sin título',
            'texto': texto,
          }),
        );
        print('Create announcement response: ${response.statusCode}');
        print('Response body: ${response.body}');
        if (response.statusCode >= 200 && response.statusCode < 300) {
          try {
            return response.body.isNotEmpty ? json.decode(response.body) : {
              'id_aviso': DateTime.now().millisecondsSinceEpoch,
              'titulo': titulo,
              'id_usuario': idUsuario
            };
          } catch (e) {
            return {
              'id_aviso': DateTime.now().millisecondsSinceEpoch,
              'titulo': titulo,
              'id_usuario': idUsuario
            };
          }
        } else if (response.statusCode == 308) {
          final redirectUrl = response.headers['location'];
          if (redirectUrl == null) {
            throw Exception('Error 308 sin URL de redirección: ${response.body}');
          }
          uri = Uri.parse(redirectUrl);
          redirectCount++;
          print('Redirecting to: $uri (intento ${redirectCount + 1})');
          continue;
        } else {
          throw Exception('Error al crear aviso: ${response.statusCode} - ${response.body}');
        }
      }
      throw Exception('Demasiadas redirecciones ($maxRedirects) al crear aviso');
    } catch (e) {
      print('Error en createAnnouncement: $e');
      rethrow;
    }
  }
  
  Future<dynamic> updateAnnouncement({
    required int announcementId,
    required int idUsuario,
    required String texto,
    String? titulo,
  }) async {
    try {
      print('Updating announcement ID: $announcementId');
      var uri = Uri.parse(ApiConnection.getAvisoByIdEndpoint(announcementId));
      const int maxRedirects = 5;
      int redirectCount = 0;
      while (redirectCount < maxRedirects) {
        final response = await http.put(
          uri,
          headers: ApiConnection.jsonHeaders,
          body: json.encode({
            'id_usuario': idUsuario,
            'titulo': titulo ?? 'Sin título',
            'texto': texto,
          }),
        );
        print('Update announcement response: ${response.statusCode}');
        print('Response body: ${response.body}');
        if (response.statusCode >= 200 && response.statusCode < 300) {
          try {
            return response.body.isNotEmpty ? json.decode(response.body) : {
              'id_aviso': announcementId,
              'titulo': titulo,
              'updated': true
            };
          } catch (e) {
            return {
              'id_aviso': announcementId,
              'titulo': titulo,
              'updated': true
            };
          }
        } else if (response.statusCode == 308) {
          final redirectUrl = response.headers['location'];
          if (redirectUrl == null) {
            throw Exception('Error 308 sin URL de redirección: ${response.body}');
          }
          uri = Uri.parse(redirectUrl);
          redirectCount++;
          print('Redirecting to: $uri (intento ${redirectCount + 1})');
          continue;
        } else {
          throw Exception('Error al actualizar aviso: ${response.statusCode} - ${response.body}');
        }
      }
      throw Exception('Demasiadas redirecciones ($maxRedirects) al actualizar aviso');
    } catch (e) {
      print('Error en updateAnnouncement: $e');
      rethrow;
    }
  }
  
  Future<void> deleteAnnouncement(int announcementId) async {
    try {
      print('Deleting announcement ID: $announcementId');
      final response = await http.delete(
        Uri.parse(ApiConnection.getAvisoByIdEndpoint(announcementId)),
        headers: ApiConnection.jsonHeaders,
      );
      _handleResponse(response);
      print('Announcement deleted successfully');
    } catch (e) {
      print('Error en deleteAnnouncement: $e');
      rethrow;
    }
  }
}