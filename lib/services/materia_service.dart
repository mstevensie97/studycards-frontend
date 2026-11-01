import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/materia.dart';

/// Error con un mensaje listo para mostrar al usuario.
class ApiException implements Exception {
  final String mensaje;
  ApiException(this.mensaje);

  @override
  String toString() => mensaje;
}

class MateriaService {
  static const _errorConexion =
      'No se pudo conectar con el servidor. Verifica que el backend esté encendido.';

  /// HU006: lista las materias con sus contadores. GET /materias
  Future<List<Materia>> listarMaterias() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/materias');

    final http.Response respuesta;
    try {
      respuesta = await http.get(uri).timeout(const Duration(seconds: 10));
    } catch (_) {
      throw ApiException(_errorConexion);
    }

    if (respuesta.statusCode != 200) {
      throw ApiException('Error inesperado (${respuesta.statusCode}).');
    }

    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes)) as List<dynamic>;
    return datos
        .map((m) => Materia.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// HU001: crea una materia. POST /materias
  /// [color] es opcional y va como hexadecimal, por ejemplo "#E53935".
  Future<void> crearMateria({
    required String nombre,
    String? descripcion,
    String? color,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/materias');

    final http.Response respuesta;
    try {
      respuesta = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'descripcion': descripcion,
          'color': color,
        }),
      )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw ApiException(_errorConexion);
    }

    if (respuesta.statusCode == 201) return;

    if (respuesta.statusCode == 400) {
      throw ApiException(
          'Los datos no son válidos. Revisa el nombre (obligatorio) y la longitud de los campos.');
    }
    throw ApiException('Error inesperado (${respuesta.statusCode}).');
  }
}