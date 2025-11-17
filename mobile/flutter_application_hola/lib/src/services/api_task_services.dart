// api_task_services.dart
import 'dart:convert';
import 'package:flutter_application_hola/src/connection/api_conection.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';


class ApiTaskServices {
  
  dynamic _handleResponse(http.Response response) {
    print('Respuesta del servidor: ${response.statusCode} - ${response.body}');
    print('Encabezados: ${response.headers}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      }
      return null;
    } else {
      throw Exception(
        'Error en la petición: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<List<dynamic>> getAllTasks() async {
    final response = await http.get(Uri.parse(ApiConnection.getTareasEndpoint()));
    return _handleResponse(response);
  }

  Future<dynamic> getTaskById(int taskId) async {
    final response = await http.get(Uri.parse(ApiConnection.getTareaByIdEndpoint(taskId)));
    return _handleResponse(response);
  }

  Future<dynamic> createTask({
    required String titulo,
    String? descripcion,
    String? fechaEntrega,
    String? horaCierre,
    required int creadoPor,
    File? archivo,
  }) async {
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

      print('Respuesta del servidor (createTask): ${response.statusCode} - $responseBody');
      print('Encabezados: ${response.headers}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody.isNotEmpty ? json.decode(responseBody) : null;
      } else if (response.statusCode == 308) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl == null) {
          throw Exception('Error 308 sin URL de redirección: $responseBody');
        }
        uri = Uri.parse(redirectUrl);
        redirectCount++;
        print('Redirigiendo a: $uri (intento ${redirectCount + 1})');
        continue;
      } else {
        throw Exception('Error al crear tarea: ${response.statusCode} - $responseBody');
      }
    }
    throw Exception('Demasiadas redirecciones ($maxRedirects) al crear tarea');
  }

  Future<dynamic> updateTask({
    required int taskId,
    required String titulo,
    String? descripcion,
    String? fechaEntrega,
    String? horaCierre,
    File? archivo,
  }) async {
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

      print('Respuesta del servidor (updateTask): ${response.statusCode} - $responseBody');
      print('Encabezados: ${response.headers}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody.isNotEmpty ? json.decode(responseBody) : null;
      } else if (response.statusCode == 308) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl == null) {
          throw Exception('Error 308 sin URL de redirección: $responseBody');
        }
        uri = Uri.parse(redirectUrl);
        redirectCount++;
        print('Redirigiendo a: $uri (intento ${redirectCount + 1})');
        continue;
      } else {
        throw Exception('Error al actualizar tarea: ${response.statusCode} - $responseBody');
      }
    }
    throw Exception('Demasiadas redirecciones ($maxRedirects) al actualizar tarea');
  }

  Future<void> deleteTask(int taskId) async {
    final response = await http.delete(Uri.parse(ApiConnection.getTareaByIdEndpoint(taskId)));
    _handleResponse(response);
  }

  Future<List<dynamic>> getDeliveriesByTask(int taskId) async {
    final response = await http.get(Uri.parse(ApiConnection.getEntregasByTaskEndpoint(taskId)));
    return _handleResponse(response);
  }

  Future<dynamic> createDelivery({
    required int taskId,
    required int alumnoId,
    File? archivo,
    double? calificacion,
    String? observaciones,
  }) async {
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

      print('Respuesta del servidor (createDelivery): ${response.statusCode} - $responseBody');
      print('Encabezados: ${response.headers}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody.isNotEmpty ? json.decode(responseBody) : null;
      } else if (response.statusCode == 308) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl == null) {
          throw Exception('Error 308 sin URL de redirección: $responseBody');
        }
        uri = Uri.parse(redirectUrl);
        redirectCount++;
        print('Redirigiendo a: $uri (intento ${redirectCount + 1})');
        continue;
      } else {
        throw Exception('Error al crear entrega: ${response.statusCode} - $responseBody');
      }
    }
    throw Exception('Demasiadas redirecciones ($maxRedirects) al crear entrega');
  }

  Future<dynamic> updateDelivery({
    required int deliveryId,
    File? archivo,
    double? calificacion,
    String? observaciones,
  }) async {
    var uri = Uri.parse(ApiConnection.getEntregaByIdEndpoint(deliveryId));
    const int maxRedirects = 5;
    int redirectCount = 0;

    while (redirectCount < maxRedirects) {
      var request = http.MultipartRequest('PUT', uri);

      if (calificacion != null) request.fields['calificacion'] = calificacion.toString();
      if (observaciones != null) request.fields['observaciones'] = observaciones;

      if (archivo != null) {
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

      print('Respuesta del servidor (updateDelivery): ${response.statusCode} - $responseBody');
      print('Encabezados: ${response.headers}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseBody.isNotEmpty ? json.decode(responseBody) : null;
      } else if (response.statusCode == 308) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl == null) {
          throw Exception('Error 308 sin URL de redirección: $responseBody');
        }
        uri = Uri.parse(redirectUrl);
        redirectCount++;
        print('Redirigiendo a: $uri (intento ${redirectCount + 1})');
        continue;
      } else {
        throw Exception('Error al actualizar entrega: ${response.statusCode} - $responseBody');
      }
    }
    throw Exception('Demasiadas redirecciones ($maxRedirects) al actualizar entrega');
  }

  Future<void> deleteDelivery(int deliveryId) async {
    final response = await http.delete(Uri.parse(ApiConnection.getEntregaByIdEndpoint(deliveryId)));
    _handleResponse(response);
  }

  Future<File> downloadFile({
    required String resourceType,
    required int resourceId,
    required String fileName,
  }) async {
    if (resourceType != 'tarea' && resourceType != 'entrega') {
      throw Exception('Tipo de recurso inválido. Use "tarea" o "entrega"');
    }

    final String fullUrl = '${ApiConnection.getDownloadEndpoint()}/$resourceType/$resourceId';
    print('Intentando descargar desde: $fullUrl');

    final response = await http.get(Uri.parse(fullUrl));

    print('Descarga - Status Code: ${response.statusCode}');
    print('Descarga - Content-Length: ${response.headers['content-length']}');
    print('Descarga - Content-Type: ${response.headers['content-type']}');

    if (response.statusCode == 200) {
      if (response.headers['content-type']?.startsWith('application/json') == true) {
        throw Exception('La respuesta es JSON, no un archivo binario: ${response.body}');
      }

      final directory = await getTemporaryDirectory();
      final sanitizedFileName = fileName.replaceAll(RegExp(r'[^\w\.]'), '_');
      final filePath = '${directory.path}/$sanitizedFileName';

      print('Intentando escribir en: $filePath');

      final file = File(filePath);
      await file.parent.create(recursive: true);
      print('Directorio creado/existe: ${file.parent.path}');

      if (response.bodyBytes.isEmpty) {
        throw Exception('No hay datos para escribir en el archivo');
      }

      try {
        await file.writeAsBytes(response.bodyBytes);
        print('Archivo escrito correctamente en: $filePath');
        return file;
      } catch (e) {
        throw Exception('Error al escribir el archivo: $e');
      }
    } else {
      try {
        final errorBody = json.decode(response.body);
        throw Exception('Error al descargar archivo: ${response.statusCode} - ${errorBody['error'] ?? response.body}');
      } catch (_) {
        throw Exception('Error al descargar archivo: ${response.statusCode} - ${response.body}');
      }
    }
  }

  Future<List<dynamic>> getTasksByUser(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConnection.getTareasEndpoint()}?user_id=$userId'),
        headers: ApiConnection.jsonHeaders,
      );
      final tasks = _handleResponse(response) as List;
      print('Tareas obtenidas para usuario $userId: $tasks');
      return tasks;
    } catch (e) {
      print('Error en getTasksByUser: $e');
      throw Exception('Error al obtener tareas del usuario: $e');
    }
  }

  Future<List<dynamic>> getPendingTasks(int alumnoId) async {
    try {
      final tasks = await getTasksByUser(alumnoId);
      final pendingTasks = tasks.where((task) {
        final status = task['status']?.toLowerCase();
        return status == 'pending' || status == 'pendiente';
      }).toList();
      print('Tareas pendientes para alumno $alumnoId: $pendingTasks');
      return pendingTasks;
    } catch (e) {
      print('Error en getPendingTasks: $e');
      throw Exception('Error al obtener tareas pendientes: $e');
    }
  }

  Future<List<dynamic>> getUpcomingTasks({int? userId}) async {
    try {
      final now = DateTime.now();
      final response = await http.get(
        Uri.parse(userId != null ? '${ApiConnection.getTareasEndpoint()}?user_id=$userId' : ApiConnection.getTareasEndpoint()),
        headers: ApiConnection.jsonHeaders,
      );
      final allTasks = _handleResponse(response) as List;

      final upcomingTasks = allTasks.where((task) {
        if (task['fecha_entrega'] == null) return false;

        final fechaEntrega = DateTime.parse(task['fecha_entrega']);
        final isUpcoming = fechaEntrega.isAfter(now) ||
            (fechaEntrega.year == now.year &&
                fechaEntrega.month == now.month &&
                fechaEntrega.day == now.day);

        return isUpcoming;
      }).toList();

      print('Tareas próximas para usuario ${userId ?? 'todos'}: $upcomingTasks');
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
      final tasks = await getTasksByUser(userId);
      final formattedTasks = <Map<String, dynamic>>[];

      for (final task in tasks) {
        List<Map<String, dynamic>> formattedEntregas = [];
        if (userRole == 'docente' || userRole == 'admin') {
          int taskId;
          try {
            taskId = int.parse(task['id'].toString());
          } catch (e) {
            print('ID de tarea inválido: ${task['id']}');
            continue;
          }
          final entregas = await getDeliveriesByTask(taskId);
          formattedEntregas = entregas.map((entrega) {
            final alumno = entrega['alumno'] != null
                ? '${entrega['alumno']['nombre'] ?? ''} ${entrega['alumno']['apellido'] ?? ''}'.trim()
                : 'Desconocido';
            return {
              'id_entrega': entrega['id'],
              'alumno': alumno,
              'archivo_ruta': entrega['archivo_ruta'] ?? 'Sin archivo',
              'fecha_entrega': entrega['fecha_entrega'] != null
                  ? DateTime.parse(entrega['fecha_entrega']).toString().split('.')[0]
                  : 'Sin fecha',
              'calificacion': entrega['calificacion']?.toString() ?? 'Sin calificar',
              'observaciones': entrega['observaciones'] ?? 'Sin observaciones',
              'id_alumno': entrega['id_alumno'],
            };
          }).toList();
        } else if (userRole == 'alumno') {
          int taskId;
          try {
            taskId = int.parse(task['id'].toString());
          } catch (e) {
            print('ID de tarea inválido: ${task['id']}');
            continue;
          }
          final entregas = await getDeliveriesByTask(taskId);
          formattedEntregas = entregas
              .where((entrega) => entrega['id_alumno'] == userId)
              .map((entrega) {
                return {
                  'id_entrega': entrega['id'],
                  'alumno': 'Tú',
                  'archivo_ruta': entrega['archivo_ruta'] ?? 'Sin archivo',
                  'fecha_entrega': entrega['fecha_entrega'] != null
                      ? DateTime.parse(entrega['fecha_entrega']).toString().split('.')[0]
                      : 'Sin fecha',
                  'calificacion': entrega['calificacion']?.toString() ?? 'Sin calificar',
                  'observaciones': entrega['observaciones'] ?? 'Sin observaciones',
                  'id_alumno': entrega['id_alumno'],
                };
              }).toList();
        }

        final fechaEntrega = task['fecha_entrega'] != null
            ? DateTime.parse(task['fecha_entrega']).toString().split(' ')[0]
            : 'Sin fecha';
        final horaCierre = task['hora_cierre']?.toString() ?? 'Sin hora';
        final creador = task['creador'] != null
            ? '${task['creador']['nombre'] ?? ''} ${task['creador']['apellido'] ?? ''}'.trim()
            : 'Desconocido';

        formattedTasks.add({
          'id': int.parse(task['id'].toString()),
          'title': task['titulo'] ?? 'Sin título',
          'description': task['descripcion'] ?? 'Sin descripción',
          'due_date': fechaEntrega,
          'due_time': horaCierre,
          'creator': creador,
          'archivo_ruta': task['archivo_ruta'] ?? 'Sin archivo',
          'status': formattedEntregas.isNotEmpty && userRole == 'alumno' ? 'entregado' : task['status']?.toLowerCase() ?? 'pending',
          'deliveries': formattedEntregas,
        });
      }

      print('Tareas formateadas para usuario $userId (rol: $userRole): $formattedTasks');
      return formattedTasks;
    } catch (e) {
      print('Error en displayTasks: $e');
      throw Exception('Error al mostrar tareas: $e');
    }
  }

  Future<List<dynamic>> getAllAnnouncements() async {
    final response = await http.get(Uri.parse(ApiConnection.getAvisosEndpoint()));
    return _handleResponse(response);
  }

  Future<dynamic> getAnnouncementById(int announcementId) async {
    final response = await http.get(Uri.parse(ApiConnection.getAvisoByIdEndpoint(announcementId)));
    return _handleResponse(response);
  }

  Future<dynamic> createAnnouncement({
    required int idUsuario,
    required String texto,
    String? titulo,
  }) async {
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

      print('Respuesta del servidor (createAnnouncement): ${response.statusCode} - ${response.body}');
      print('Encabezados: ${response.headers}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body.isNotEmpty ? json.decode(response.body) : null;
      } else if (response.statusCode == 308) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl == null) {
          throw Exception('Error 308 sin URL de redirección: ${response.body}');
        }
        uri = Uri.parse(redirectUrl);
        redirectCount++;
        print('Redirigiendo a: $uri (intento ${redirectCount + 1})');
        continue;
      } else {
        throw Exception('Error al crear aviso: ${response.statusCode} - ${response.body}');
      }
    }
    throw Exception('Demasiadas redirecciones ($maxRedirects) al crear aviso');
  }

  Future<dynamic> updateAnnouncement({
    required int announcementId,
    required int idUsuario,
    required String texto,
    String? titulo,
  }) async {
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

      print('Respuesta del servidor (updateAnnouncement): ${response.statusCode} - ${response.body}');
      print('Encabezados: ${response.headers}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body.isNotEmpty ? json.decode(response.body) : null;
      } else if (response.statusCode == 308) {
        final redirectUrl = response.headers['location'];
        if (redirectUrl == null) {
          throw Exception('Error 308 sin URL de redirección: ${response.body}');
        }
        uri = Uri.parse(redirectUrl);
        redirectCount++;
        print('Redirigiendo a: $uri (intento ${redirectCount + 1})');
        continue;
      } else {
        throw Exception('Error al actualizar aviso: ${response.statusCode} - ${response.body}');
      }
    }
    throw Exception('Demasiadas redirecciones ($maxRedirects) al actualizar aviso');
  }

  Future<void> deleteAnnouncement(int announcementId) async {
    final response = await http.delete(Uri.parse(ApiConnection.getAvisoByIdEndpoint(announcementId)));
    _handleResponse(response);
  }
}