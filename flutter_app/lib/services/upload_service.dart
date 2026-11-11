import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Modelo simple para representar el resultado de una operación de subida.
class UploadResult {
  final bool isSuccess;
  final String message;
  final int? fileId;
  final String? fileName;
  final int? fileSize;

  UploadResult({
    required this.isSuccess,
    required this.message,
    this.fileId,
    this.fileName,
    this.fileSize,
  });

  factory UploadResult.success({
    required String message,
    required int fileId,
    required String fileName,
    int? fileSize,
  }) {
    return UploadResult(
      isSuccess: true,
      message: message,
      fileId: fileId,
      fileName: fileName,
      fileSize: fileSize,
    );
  }

  factory UploadResult.failure(String message) {
    return UploadResult(
      isSuccess: false,
      message: message,
    );
  }
}

/// Servicio encargado de la selección y subida de archivos al backend.
class UploadService {
  final String _baseUrl;
  final http.Client _client;

  UploadService({String? baseUrl, http.Client? client})
      : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _client = client ?? http.Client();

  /// Abre el explorador de archivos nativo para que el usuario seleccione un archivo.
  Future<PlatformFile?> pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: false,
        withData: true, // Habilita bytes para compatibilidad web y móvil
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      // TODO: Registrar excepción en servicio de monitoreo/analytics
      return null;
    }
  }

  /// Sube el archivo seleccionado al endpoint `POST /files/upload` mediante multipart.
  Future<UploadResult> uploadFile(PlatformFile file) async {
    final uploadUri = Uri.parse('$_baseUrl/files/upload');

    try {
      final request = http.MultipartRequest('POST', uploadUri);

      // TODO: Añadir token de autenticación cuando se implemente login:
      // request.headers['Authorization'] = 'Bearer $authToken';

      if (file.bytes != null) {
        // Enfoque compatible con Web y buffers en memoria
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );
      } else if (file.path != null) {
        // Enfoque desde ruta física en el sistema de archivos
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path!,
            filename: file.name,
          ),
        );
      } else {
        return UploadResult.failure(
          'No se pudo acceder a los datos del archivo seleccionado.',
        );
      }

      // Enviar solicitud con límite de tiempo
      final streamedResponse = await _client.send(request).timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final fileData = data['file'] as Map<String, dynamic>?;

        final int fileId = fileData?['id'] ?? 0;
        final String fileName = fileData?['filename'] ?? file.name;
        final int? fileSize = fileData?['file_size'];

        return UploadResult.success(
          message: data['message'] ?? 'Archivo subido con éxito.',
          fileId: fileId,
          fileName: fileName,
          fileSize: fileSize,
        );
      } else {
        String errorMessage = 'Error al subir archivo (${response.statusCode})';
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody is Map && errorBody.containsKey('detail')) {
            errorMessage = errorBody['detail'].toString();
          }
        } catch (_) {
          // Si el cuerpo no es JSON, conservar el mensaje genérico
        }
        return UploadResult.failure(errorMessage);
      }
    } on http.ClientException catch (e) {
      return UploadResult.failure(
        'Error de conexión con el servidor: ${e.message}. Verifica que el backend esté iniciado en $_baseUrl',
      );
    } catch (e) {
      return UploadResult.failure(
        'Error inesperado durante la subida: $e',
      );
    }
  }
}
