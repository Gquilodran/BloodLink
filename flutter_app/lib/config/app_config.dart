import 'package:flutter/foundation.dart';

/// Configuración global de la aplicación.
///
/// La URL base de la API se lee en tiempo de compilación con `--dart-define`.
/// Si no se especifica `--dart-define=API_BASE_URL=...`, selecciona
/// automáticamente `http://10.0.2.2:8000` en Android y `http://127.0.0.1:8000`
/// en Web, Windows, macOS, Linux e iOS.
///
/// Ejemplos de uso según el entorno de ejecución:
/// - Emulador Android: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`
/// - Dispositivo físico / Red local: `flutter run --dart-define=API_BASE_URL=http://192.168.1.X:8000`
/// - Web / Windows Desktop: `flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000`
class AppConfig {
  AppConfig._();

  static const String _envApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// URL base del backend de BloodLink.
  /// La app cliente NUNCA contiene credenciales ni llaves de la base de datos;
  /// solo conoce esta URL base para comunicarse con los endpoints de la API.
  static String get apiBaseUrl {
    if (_envApiBaseUrl.isNotEmpty) {
      return _envApiBaseUrl.endsWith('/')
          ? _envApiBaseUrl.substring(0, _envApiBaseUrl.length - 1)
          : _envApiBaseUrl;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }
}
