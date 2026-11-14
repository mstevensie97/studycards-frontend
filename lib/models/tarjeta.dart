/// Una tarjeta tal como la devuelve el backend.
class Tarjeta {
  final int id;
  final String pregunta;
  final String respuesta;
  final String nivelDominio; // "REPASAR" o "APRENDIDA"
  final int materiaId;

  const Tarjeta({
    required this.id,
    required this.pregunta,
    required this.respuesta,
    required this.nivelDominio,
    required this.materiaId,
  });

  factory Tarjeta.fromJson(Map<String, dynamic> json) {
    return Tarjeta(
      id: json['id'] as int,
      pregunta: json['pregunta'] as String,
      respuesta: json['respuesta'] as String,
      nivelDominio: json['nivelDominio'] as String? ?? 'REPASAR',
      materiaId: json['materiaId'] as int,
    );
  }

  bool get estaAprendida => nivelDominio == 'APRENDIDA';
}

/// Respuesta de GET /materias/{id}/tarjetas: nombre de la materia,
/// total y la lista de tarjetas.
class ListadoTarjetas {
  final int materiaId;
  final String materia;
  final int total;
  final List<Tarjeta> tarjetas;

  const ListadoTarjetas({
    required this.materiaId,
    required this.materia,
    required this.total,
    required this.tarjetas,
  });

  factory ListadoTarjetas.fromJson(Map<String, dynamic> json) {
    return ListadoTarjetas(
      materiaId: json['materiaId'] as int,
      materia: json['materia'] as String,
      total: (json['total'] as num?)?.toInt() ?? 0,
      tarjetas: (json['tarjetas'] as List<dynamic>)
          .map((t) => Tarjeta.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}