/// Configuración global de la aplicación.
///
/// La URL base de la API se lee en tiempo de compilación con `--dart-define`.
///
/// Ejemplos de uso según el entorno de ejecución:
/// - Emulador Android: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`
/// - Dispositivo físico / Red local: `flutter run --dart-define=API_BASE_URL=http://192.168.1.X:8000`
/// - Web / Windows Desktop: `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000`
class AppConfig {
  AppConfig._();

  /// URL base del backend de BloodLink.
  /// La app móvil NUNCA contiene credenciales ni llaves de la base de datos;
  /// solo conoce esta URL base para comunicarse con los endpoints públicos del backend.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
