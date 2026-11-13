import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/sesion_estudio.dart';
import 'materia_service.dart' show ApiException;

class EstudioService {
  static const _errorConexion =
      'No se pudo conectar con el servidor. Verifica que el backend esté encendido.';

  /// HU012: inicia una sesión de estudio. GET /materias/{id}/estudio
  Future<SesionEstudio> iniciarSesion(int materiaId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/materias/$materiaId/estudio');

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
        return SesionEstudio.fromJson(json);
      case 404:
        throw ApiException('La materia ya no existe.');
      default:
        throw ApiException('Error inesperado (${respuesta.statusCode}).');
    }
  }
}