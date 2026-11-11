import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/upload_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final UploadService _uploadService = UploadService();
  bool _isUploading = false;
  String? _lastUploadedFileName;
  int? _lastUploadedFileId;

  Future<void> _handleUpload() async {
    // 1. Seleccionar archivo del dispositivo
    final pickedFile = await _uploadService.pickFile();
    if (pickedFile == null) {
      // El usuario canceló la selección
      return;
    }

    setState(() {
      _isUploading = true;
    });

    // 2. Subir archivo al backend
    final result = await _uploadService.uploadFile(pickedFile);

    if (!mounted) return;

    setState(() {
      _isUploading = false;
      if (result.isSuccess) {
        _lastUploadedFileName = result.fileName;
        _lastUploadedFileId = result.fileId;
      }
    });

    // 3. Mostrar el resultado en un SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess
              ? '${result.message} (ID: ${result.fileId})'
              : result.message,
        ),
        backgroundColor: result.isSuccess ? Colors.green.shade700 : Colors.red.shade700,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BloodLink - Subir Archivo'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_upload_outlined,
                size: 72,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Subida de Archivos al Servidor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'API Base: ${AppConfig.apiBaseUrl}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_isUploading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Subiendo archivo al backend...'),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _handleUpload,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Subir archivo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_lastUploadedFileId != null && _lastUploadedFileName != null) ...[
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        const Text(
                          'Último archivo subido:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text('Nombre: $_lastUploadedFileName'),
                        Text('ID en BD: $_lastUploadedFileId'),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
