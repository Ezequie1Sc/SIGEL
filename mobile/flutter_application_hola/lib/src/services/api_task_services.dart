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

  // MÉTODO DOWNLOADFILE COMPLETAMENTE CORREGIDO
  Future<File> downloadFile({
    required String resourceType,
    required int resourceId,
    required String filePath,
  }) async {
    try {
      print('=== DOWNLOAD FILE START ===');
      print('Resource Type: $resourceType');
      print('Resource ID: $resourceId');
      print('File Path: $filePath');
      
      if (resourceType != 'tarea' && resourceType != 'entrega') {
        throw Exception('Tipo de recurso inválido. Use "tarea" o "entrega"');
      }

    // Validar filePath
    if (filePath.isEmpty || filePath == 'Sin archivo') {
      throw Exception('No hay archivo disponible para descargar');
    }

    // Decodificar caracteres especiales
    filePath = Uri.decodeFull(filePath);
    
    // Extraer el nombre del archivo de la ruta
    String fileName = filePath.split('/').last;
    
    // Construir URL - PRIMER INTENTO: usando el filePath completo como parámetro
    String endpoint;
    if (resourceType == 'tarea') {
      endpoint = '${ApiConnection.baseUrl}/api/tareas/$resourceId/descargar?file=${Uri.encodeComponent(filePath)}';
    } else {
      endpoint = '${ApiConnection.baseUrl}/api/entregas/$resourceId/descargar?file=${Uri.encodeComponent(filePath)}';
    }
    
    print('Download URL (Attempt 1): $endpoint');

    // Realizar la petición GET
    final response = await http.get(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/octet-stream',
        'Accept': 'application/octet-stream',
        ...ApiConnection.jsonHeaders,
      },
    );

    print('Download Response Status: ${response.statusCode}');
    print('Response Content-Type: ${response.headers['content-type']}');
    print('Response Headers: ${response.headers}');

    if (response.statusCode == 200) {
      // Verificar si es un archivo binario
      final contentType = response.headers['content-type'] ?? '';
      
      if (contentType.startsWith('application/json')) {
        // Si el servidor devuelve JSON en lugar del archivo
        try {
          final errorData = json.decode(response.body);
          throw Exception('Error del servidor: ${errorData['error'] ?? errorData['message'] ?? response.body}');
        } catch (e) {
          throw Exception('Error del servidor: ${response.body}');
        }
      }
      
      // Sanitizar el nombre del archivo
      String safeFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      if (safeFileName.isEmpty) {
        safeFileName = 'archivo_descargado_${DateTime.now().millisecondsSinceEpoch}';
      }
      
      // Obtener directorio para guardar
      final directory = await getApplicationDocumentsDirectory();
      final filePathLocal = '${directory.path}/downloads/$safeFileName';
      
      // Crear directorio si no existe
      final downloadDir = Directory('${directory.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      
      // Guardar el archivo
      final file = File(filePathLocal);
      await file.writeAsBytes(response.bodyBytes);
      
      // Verificar que se guardó correctamente
      final fileSize = await file.length();
      if (fileSize > 0) {
        print('✅ File downloaded successfully!');
        print('   Local Path: ${file.path}');
        print('   Size: $fileSize bytes');
        return file;
      } else {
        throw Exception('El archivo descargado está vacío');
      }
    } 
    // Si falla con el path completo, intentar solo con el nombre del archivo
    else if (response.statusCode == 404 || response.statusCode == 400) {
      print('First attempt failed with ${response.statusCode}, trying with filename only');
      
      // SEGUNDO INTENTO: Usar solo el nombre del archivo
      String secondEndpoint;
      if (resourceType == 'tarea') {
        secondEndpoint = '${ApiConnection.baseUrl}/api/tareas/$resourceId/descargar?file=${Uri.encodeComponent(fileName)}';
      } else {
        secondEndpoint = '${ApiConnection.baseUrl}/api/entregas/$resourceId/descargar?file=${Uri.encodeComponent(fileName)}';
      }
      
      print('Download URL (Attempt 2): $secondEndpoint');
      
      final secondResponse = await http.get(
        Uri.parse(secondEndpoint),
        headers: {
          'Content-Type': 'application/octet-stream',
          'Accept': 'application/octet-stream',
          ...ApiConnection.jsonHeaders,
        },
      );
      
      if (secondResponse.statusCode == 200) {
        // Guardar el archivo (código similar al anterior)
        String safeFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
        if (safeFileName.isEmpty) {
          safeFileName = 'archivo_descargado_${DateTime.now().millisecondsSinceEpoch}';
        }
        
        final directory = await getApplicationDocumentsDirectory();
        final filePathLocal = '${directory.path}/downloads/$safeFileName';
        
        final downloadDir = Directory('${directory.path}/downloads');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        
        final file = File(filePathLocal);
        await file.writeAsBytes(secondResponse.bodyBytes);
        
        final fileSize = await file.length();
        if (fileSize > 0) {
          print('✅ File downloaded successfully (second attempt)!');
          print('   Local Path: ${file.path}');
          print('   Size: $fileSize bytes');
          return file;
        }
      }
      
      // Si ambos intentos fallan, probar endpoints alternativos
      return await _tryAlternativeDownloadMethods(resourceType, resourceId, filePath, fileName);
    } 
    else {
      String errorMessage = 'Error ${response.statusCode} al descargar archivo';
      try {
        final errorData = json.decode(response.body);
        errorMessage += ': ${errorData['error'] ?? errorData['message'] ?? response.body}';
      } catch (_) {
        if (response.body.isNotEmpty) {
          errorMessage += ': ${response.body}';
        }
      }
      throw Exception(errorMessage);
    }
  } catch (e) {
    print('❌ Error en downloadFile: $e');
    print('Stack trace: ${e.toString()}');
    
    // Intentar métodos alternativos como último recurso
    try {
      return await _tryAlternativeDownloadMethods(
        resourceType, 
        resourceId, 
        filePath, 
        filePath.split('/').last
      );
    } catch (e2) {
      rethrow;
    }
  }
}

// Método auxiliar para intentar diferentes formatos de URL
Future<File> _tryAlternativeDownloadMethods(
  String resourceType, 
  int resourceId, 
  String filePath, 
  String fileName
) async {
  print('=== TRYING ALTERNATIVE DOWNLOAD METHODS ===');
  
  // Diferentes formatos de URL que podrían funcionar
  final urlFormats = [
    // Formato 1: Con el path completo codificado
    '${ApiConnection.baseUrl}/api/$resourceType/$resourceId/download?path=${Uri.encodeComponent(filePath)}',
    
    // Formato 2: Con solo el nombre del archivo
    '${ApiConnection.baseUrl}/api/$resourceType/$resourceId/download?filename=${Uri.encodeComponent(fileName)}',
    
    // Formato 3: Sin parámetros
    '${ApiConnection.baseUrl}/api/$resourceType/$resourceId/download',
    
    // Formato 4: Ruta directa al archivo
    '${ApiConnection.baseUrl}/api/$resourceType/$resourceId/file',
    
    // Formato 5: Otra variante común
    '${ApiConnection.baseUrl}/api/download/$resourceType/$resourceId',
  ];
  
  for (int i = 0; i < urlFormats.length; i++) {
    final url = urlFormats[i];
    try {
      print('Trying alternative URL $i: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConnection.jsonHeaders,
      );
      
      print('Alternative $i response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Sanitizar nombre del archivo
        String safeFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
        if (safeFileName.isEmpty) {
          safeFileName = 'archivo_descargado_${DateTime.now().millisecondsSinceEpoch}';
        }
        
        // Guardar el archivo
        final directory = await getApplicationDocumentsDirectory();
        final downloadDir = Directory('${directory.path}/downloads');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
        
        final filePathLocal = '${directory.path}/downloads/$safeFileName';
        final file = File(filePathLocal);
        await file.writeAsBytes(response.bodyBytes);
        
        if (await file.length() > 0) {
          print('✅ Success with alternative URL $i');
          return file;
        }
      }
    } catch (e) {
      print('Failed with alternative URL $i: $e');
      continue;
    }
  }
  
  throw Exception('No se pudo descargar el archivo con ninguna de las rutas disponibles. Verifica la configuración del servidor.');
}

  // Método alternativo de descarga si el principal falla
  Future<File> downloadFileAlternative({
    required String resourceType,
    required int resourceId,
    required String fileName,
  }) async {
    try {
      print('=== ALTERNATIVE DOWNLOAD ===');
      
      // Intentar diferentes formatos de URL
      final urlFormats = [
        '${ApiConnection.baseUrl}/api/descargar/$resourceType/$resourceId/$fileName',
        '${ApiConnection.baseUrl}/api/$resourceType/$resourceId/archivo',
        '${ApiConnection.baseUrl}/uploads/$resourceType/${fileName.split('/').last}',
        '${ApiConnection.baseUrl}/archivos/$resourceType/$resourceId',
      ];
      
      for (final url in urlFormats) {
        try {
          print('Trying URL: $url');
          final response = await http.get(Uri.parse(url));
          
          if (response.statusCode == 200) {
            final directory = await getApplicationDocumentsDirectory();
            final safeFileName = fileName.split('/').last.replaceAll(RegExp(r'[^\w\.-]'), '_');
            final filePath = '${directory.path}/$safeFileName';
            
            final file = File(filePath);
            await file.writeAsBytes(response.bodyBytes);
            
            print('✅ Success with alternative URL');
            return file;
          }
        } catch (e) {
          print('Failed with URL $url: $e');
          continue;
        }
      }
      
      throw Exception('No se pudo descargar el archivo con ninguna de las rutas disponibles');
    } catch (e) {
      print('Error en downloadFileAlternative: $e');
      rethrow;
    }
  }

  // Método para verificar si el archivo existe en el servidor
  Future<bool> checkFileExists({
    required String resourceType,
    required int resourceId,
    required String filePath,
  }) async {
    try {
      final endpoint = '${ApiConnection.baseUrl}/api/$resourceType/$resourceId/check-file?file=${Uri.encodeComponent(filePath)}';
      final response = await http.head(Uri.parse(endpoint));
      
      print('Check file exists response: ${response.statusCode}');
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
        print('  Task ${task['id']}: ${task['title']}');
        print('    Status: ${task['status']}');
        print('    Deliveries: ${task['deliveries'].length}');
        print('    File: ${task['archivo_ruta']}');
        if (task['deliveries'].isNotEmpty) {
          print('    First delivery calificacion: ${task['deliveries'][0]['calificacion']}');
          print('    First delivery file: ${task['deliveries'][0]['archivo_ruta']}');
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