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

/// HU004: el backend avisa que la materia tiene tarjetas y pide confirmación.
class AdvertenciaEliminacion {
  final String mensaje;
  final int totalTarjetas;

  const AdvertenciaEliminacion({
    required this.mensaje,
    required this.totalTarjetas,
  });
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

  /// HU003 / HU004: elimina una materia. DELETE /materias/{id}?confirmar=...
  ///
  /// - Devuelve null si la materia quedó eliminada.
  /// - Devuelve una [AdvertenciaEliminacion] si la materia tiene tarjetas y
  ///   todavía no se confirmó (el backend responde 409). En ese caso no se
  ///   borró nada: la pantalla debe preguntar al usuario y, si acepta,
  ///   volver a llamar con confirmar: true.
  Future<AdvertenciaEliminacion?> eliminarMateria(
      int id, {
        bool confirmar = false,
      }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/materias/$id')
        .replace(queryParameters: {'confirmar': confirmar.toString()});

    final http.Response respuesta;
    try {
      respuesta = await http.delete(uri).timeout(const Duration(seconds: 10));
    } catch (_) {
      throw ApiException(_errorConexion);
    }

    switch (respuesta.statusCode) {
      case 204:
        return null;
      case 409:
        final json =
        jsonDecode(utf8.decode(respuesta.bodyBytes)) as Map<String, dynamic>;
        return AdvertenciaEliminacion(
          mensaje: json['mensaje'] as String? ?? 'La materia tiene tarjetas.',
          totalTarjetas: (json['totalTarjetas'] as num?)?.toInt() ?? 0,
        );
      case 404:
        throw ApiException('La materia ya no existe.');
      default:
        throw ApiException('Error inesperado (${respuesta.statusCode}).');
    }
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