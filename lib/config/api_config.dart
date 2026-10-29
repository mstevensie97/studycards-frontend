import 'package:flutter/foundation.dart' show kIsWeb;

/// Dirección base del backend.
/// - En Chrome (web) el backend local se alcanza con localhost.
/// - En el emulador de Android, localhost es el propio emulador,
///   y 10.0.2.2 es el computador donde corre Quarkus.
/// Cuando despleguemos en Render, aquí se cambia por la URL pública.
class ApiConfig {
  static String get baseUrl =>
      kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
}