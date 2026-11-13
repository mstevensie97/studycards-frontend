import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/progreso.dart';
import 'materia_service.dart' show ApiException;

class ProgresoService {
  static const _errorConexion =
      'No se pudo conectar con el servidor. Verifica que el backend esté encendido.';

  /// RQ-15: progreso de estudio de una materia. GET /materias/{id}/progreso
  Future<Progreso> consultar(int materiaId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/materias/$materiaId/progreso');

    final http.Response respuesta;
    try {
      respuesta = await http.get(uri).timeout(const Duration(seconds: 10));
    } catch (_) {
      throw ApiException(_errorConexion);
    }

    switch (respuesta.statusCode) {
      case 200:
        final json =
        jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
        return Progreso.fromJson(json);
      case 404:
        throw ApiException('La materia ya no existe.');
      default:
        throw ApiException('Error inesperado (${respuesta.statusCode}).');
    }
  }
}