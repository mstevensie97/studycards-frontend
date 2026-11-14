import 'package:flutter/material.dart';

/// Colores con significado para toda la app:
/// verde = dominada, naranja = falta repasar. El indigo (color principal
/// del tema) queda para navegar: Siguiente, Estudiar, Guardar, etc.
class AppColors {
  AppColors._();

  static const aprendida = Color(0xFF2E7D32); // verde
  static const aprendidaFondo = Color(0xFFE8F5E9);

  static const repasar = Color(0xFFEF6C00); // naranja
  static const repasarFondo = Color(0xFFFFF3E0);
}