/// Respuesta de GET /materias/{id}/progreso.
class Progreso {
  final int materiaId;
  final String materia;
  final int totalTarjetas;
  final int estudiadas;
  final int aprendidas;
  final int porcentajeAprendidas;

  const Progreso({
    required this.materiaId,
    required this.materia,
    required this.totalTarjetas,
    required this.estudiadas,
    required this.aprendidas,
    required this.porcentajeAprendidas,
  });

  factory Progreso.fromJson(Map<String, dynamic> json) {
    return Progreso(
      materiaId: json['materiaId'] as int,
      materia: json['materia'] as String,
      totalTarjetas: (json['totalTarjetas'] as num?)?.toInt() ?? 0,
      estudiadas: (json['estudiadas'] as num?)?.toInt() ?? 0,
      aprendidas: (json['aprendidas'] as num?)?.toInt() ?? 0,
      porcentajeAprendidas: (json['porcentajeAprendidas'] as num?)?.toInt() ?? 0,
    );
  }
}