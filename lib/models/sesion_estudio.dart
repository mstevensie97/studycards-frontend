import 'tarjeta.dart';

/// Respuesta de GET /materias/{id}/estudio: las tarjetas a estudiar,
/// ya en el orden en que se deben mostrar.
class SesionEstudio {
  final int materiaId;
  final String materia;
  final int total;
  final List<Tarjeta> tarjetas;

  const SesionEstudio({
    required this.materiaId,
    required this.materia,
    required this.total,
    required this.tarjetas,
  });

  factory SesionEstudio.fromJson(Map<String, dynamic> json) {
    return SesionEstudio(
      materiaId: json['materiaId'] as int,
      materia: json['materia'] as String,
      total: (json['total'] as num?)?.toInt() ?? 0,
      tarjetas: (json['tarjetas'] as List<dynamic>)
          .map((t) => Tarjeta.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}