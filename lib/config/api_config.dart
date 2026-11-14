/// Dirección base del backend.
///
/// Por defecto la app usa el backend desplegado en Render, así el APK
/// funciona en cualquier celular con internet.
///
/// Para probar contra el backend local (Quarkus en tu computador) se puede
/// sobreescribir al ejecutar:
///   flutter run -d chrome --dart-define=API_URL=http://localhost:8080
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://studycards-backend.onrender.com',
  );
}