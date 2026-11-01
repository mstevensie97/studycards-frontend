import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/tarjeta.dart';
import 'materia_service.dart' show ApiException;

class TarjetaService {
  static const _errorConexion =
      'No se pudo conectar con el servidor. Verifica que el backend esté encendido.';

  /// HU011: lista las tarjetas de una materia. GET /materias/{id}/tarjetas
  Future<ListadoTarjetas> listarTarjetas(int materiaId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/materias/$materiaId/tarjetas');

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
        return ListadoTarjetas.fromJson(json);
      case 404:
        throw ApiException('La materia ya no existe.');
      default:
        throw ApiException('Error inesperado (${respuesta.statusCode}).');
    }
  }

  /// HU008: crea una tarjeta en una materia. POST /materias/{id}/tarjetas
  Future<void> crearTarjeta({
    required int materiaId,
    required String pregunta,
    required String respuesta,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/materias/$materiaId/tarjetas');

    final http.Response resp;
    try {
      resp = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pregunta': pregunta, 'respuesta': respuesta}),
      )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      throw ApiException(_errorConexion);
    }

    switch (resp.statusCode) {
      case 201:
        return;
      case 400:
        throw ApiException(
            'Datos no válidos. La pregunta (máx. 500 caracteres) y la respuesta (máx. 1000) son obligatorias.');
      case 404:
        throw ApiException('La materia ya no existe.');
      default:
        throw ApiException('Error inesperado (${resp.statusCode}).');
    }
  }
}