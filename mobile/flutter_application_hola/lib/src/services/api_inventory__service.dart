import 'dart:convert';
import 'package:flutter_application_hola/src/connection/api_conection.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';


class ApiService {
  // Headers
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static dynamic _handleResponse(http.Response response) {
    debugPrint('Response status: ${response.statusCode}');
    debugPrint('Response body: ${response.body}');
    
    if (response.statusCode == 308) {
      // Manejar redirección 308
      final location = response.headers['location'];
      if (location != null) {
        throw Exception('Redirección requerida a: $location');
      }
      throw Exception('Redirección 308 sin cabecera Location');
    }
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  static Future<dynamic> _handleRedirects(http.BaseRequest request) async {
    var response = await http.Response.fromStream(await http.Client().send(request));
    
    if (response.statusCode == 308) {
      final location = response.headers['location'];
      if (location != null) {
        // Crear nueva solicitud a la ubicación de redirección
        var newRequest = http.Request(request.method, Uri.parse(location))
          ..headers.addAll(request.headers);
        
        if (request is http.Request) {
          newRequest.body = (request as http.Request).body;
        }
        
        response = await http.Response.fromStream(await http.Client().send(newRequest));
      }
    }
    
    return response;
  }

  // Obtener todos los reactivos
  static Future<List<dynamic>> getReactivos() async {
    final request = http.Request('GET', Uri.parse(ApiConnection.getReactivosEndpoint()));
    request.headers.addAll(headers);
    final response = await _handleRedirects(request);
    return _handleResponse(response);
  }

  // Obtener todas las categorías
  static Future<List<dynamic>> getCategorias() async {
    final request = http.Request('GET', Uri.parse(ApiConnection.getCategoriasEndpoint()));
    request.headers.addAll(headers);
    final response = await _handleRedirects(request);
    return _handleResponse(response);
  }

  // Crear un nuevo reactivo
  static Future<dynamic> createReactivo({
    required String nombre,
    required double cantidad,
    required String unidad,
    required double minimo,
    required String ubicacion,
    required int idCategoria,
    int? creadoPor,
  }) async {
    final data = {
      'nombre': nombre,
      'cantidad': cantidad,
      'unidad': unidad,
      'minimo': minimo,
      'ubicacion': ubicacion,
      'id_categoria': idCategoria,
      if (creadoPor != null) 'creado_por': creadoPor,
    };
    
    final request = http.Request('POST', Uri.parse(ApiConnection.getReactivosEndpoint()));
    request.headers.addAll(headers);
    request.body = json.encode(data);
    
    final response = await _handleRedirects(request);
    return _handleResponse(response);
  }

  // Actualizar un reactivo existente
  static Future<dynamic> updateReactivo({
    required int idReactivo,
    required String nombre,
    required double cantidad,
    required String unidad,
    required double minimo,
    required String ubicacion,
    required int idCategoria,
  }) async {
    final data = {
      'nombre': nombre,
      'cantidad': cantidad,
      'unidad': unidad,
      'minimo': minimo,
      'ubicacion': ubicacion,
      'id_categoria': idCategoria,
    };
    
    final request = http.Request('PUT', Uri.parse(ApiConnection.getReactivoByIdEndpoint(idReactivo)));
    request.headers.addAll(headers);
    request.body = json.encode(data);
    
    final response = await _handleRedirects(request);
    return _handleResponse(response);
  }

  // Eliminar un reactivo
  static Future<dynamic> deleteReactivo(int idReactivo) async {
    final request = http.Request('DELETE', Uri.parse(ApiConnection.getReactivoByIdEndpoint(idReactivo)));
    request.headers.addAll(headers);
    
    final response = await _handleRedirects(request);
    return _handleResponse(response);
  }

  // Crear una nueva categoría
  static Future<dynamic> createCategoria({
    required String nombre,
    String? descripcion,
  }) async {
    final data = {
      'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
    };
    
    final request = http.Request('POST', Uri.parse(ApiConnection.getCategoriasEndpoint()));
    request.headers.addAll(headers);
    request.body = json.encode(data);
    
    final response = await _handleRedirects(request);
    return _handleResponse(response);
  }

  // Eliminar una categoría
  static Future<dynamic> deleteCategoria(int idCategoria) async {
    final request = http.Request('DELETE', Uri.parse(ApiConnection.getCategoriaByIdEndpoint(idCategoria)));
    request.headers.addAll(headers);
    
    final response = await _handleRedirects(request);
    return _handleResponse(response);
  }

  static getUsuarioById(param0) {}
}