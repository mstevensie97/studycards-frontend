import 'package:flutter/material.dart';

/// Una materia tal como la devuelve GET /materias del backend.
class Materia {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? color; // hexadecimal, por ejemplo "#E53935"
  final int totalTarjetas;
  final int tarjetasPendientes;

  const Materia({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.color,
    required this.totalTarjetas,
    required this.tarjetasPendientes,
  });

  factory Materia.fromJson(Map<String, dynamic> json) {
    return Materia(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      color: json['color'] as String?,
      totalTarjetas: (json['totalTarjetas'] as num?)?.toInt() ?? 0,
      tarjetasPendientes: (json['tarjetasPendientes'] as num?)?.toInt() ?? 0,
    );
  }

  /// Convierte el color hexadecimal en un Color de Flutter.
  /// Si la materia no tiene color (o viene vacío o inválido), devuelve gris.
  Color get colorFlutter {
    final hex = color;
    if (hex == null || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) {
      return Colors.grey;
    }
    return Color(int.parse('FF${hex.substring(1)}', radix: 16));
  }
}