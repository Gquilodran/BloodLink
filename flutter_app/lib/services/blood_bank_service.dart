import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class BloodBankException implements Exception {
  final String message;

  BloodBankException(this.message);

  @override
  String toString() => message;
}

class UnidadSangre {
  final int id;
  final String tipoSangre;
  final String donante;
  final String ubicacion;
  final String fechaExtraccion;
  final String fechaCaducidad;
  final int cantidadMl;

  UnidadSangre({
    required this.id,
    required this.tipoSangre,
    required this.donante,
    required this.ubicacion,
    required this.fechaExtraccion,
    required this.fechaCaducidad,
    required this.cantidadMl,
  });

  factory UnidadSangre.fromJson(Map<String, dynamic> json) {
    return UnidadSangre(
      id: (json['id'] as num).toInt(),
      tipoSangre: (json['nombre_tipo_sangre'] ?? '').toString(),
      donante: (json['nombre_donante'] ?? 'Sin registrar').toString(),
      ubicacion: (json['nombre_ubicacion'] ?? 'Sin ubicación').toString(),
      fechaExtraccion: _formatearFechaHora(json['fecha_hora_extraccion']),
      fechaCaducidad: _formatearFecha(json['fecha_caducidad']),
      cantidadMl: (json['cantidad_ml'] as num?)?.toInt() ?? 200,
    );
  }
}

class SolicitudSangre {
  final int id;
  final String tipoSangre;
  final double cantidadMl;
  final String prioridad;
  final String centroSalud;
  final String estado;
  final String fechaSolicitud;
  final String? fechaCompletada;

  SolicitudSangre({
    required this.id,
    required this.tipoSangre,
    required this.cantidadMl,
    required this.prioridad,
    required this.centroSalud,
    required this.estado,
    required this.fechaSolicitud,
    this.fechaCompletada,
  });

  factory SolicitudSangre.fromJson(Map<String, dynamic> json) {
    final completadaRaw = json['fecha_completada'];
    return SolicitudSangre(
      id: (json['id'] as num).toInt(),
      tipoSangre: (json['nombre_tipo_sangre'] ?? '').toString(),
      cantidadMl: (json['cantidad_ml'] as num).toDouble(),
      prioridad: (json['prioridad'] ?? '').toString(),
      centroSalud: (json['centro_salud'] ?? 'N/A').toString(),
      estado: (json['estado'] ?? 'pendiente').toString().toLowerCase(),
      fechaSolicitud: _formatearFechaHora(json['fecha_solicitud']),
      fechaCompletada: completadaRaw != null
          ? _formatearFechaHora(completadaRaw)
          : null,
    );
  }
}

String _formatearFechaHora(dynamic raw) {
  if (raw == null) return '';
  final texto = raw.toString().replaceFirst('T', ' ');
  return texto.length >= 16 ? texto.substring(0, 16) : texto;
}

String _formatearFecha(dynamic raw) {
  if (raw == null) return '';
  final texto = raw.toString();
  return texto.length >= 10 ? texto.substring(0, 10) : texto;
}

class BloodBankService {
  final String _baseUrl;
  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 15);

  BloodBankService({String? baseUrl, http.Client? client})
      : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _client = client ?? http.Client();

  Map<String, String> get _jsonHeaders => const {
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      };

  dynamic _decodificarRespuesta(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body.trim().isEmpty) return null;
      return jsonDecode(body);
    }

    String detalle = 'Error del servidor (${response.statusCode})';
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map && parsed['detail'] != null) {
        detalle = parsed['detail'].toString();
      }
    } catch (_) {
      if (body.isNotEmpty) detalle = body;
    }
    throw BloodBankException(detalle);
  }

  String _mensajeConexion(Object error) {
    if (error is BloodBankException) return error.message;
    return 'No se pudo conectar con el servidor ($_baseUrl). '
        'Verifica que el backend esté iniciado.';
  }

  Future<List<UnidadSangre>> obtenerUnidades({String? tipoSangre}) async {
    final query = (tipoSangre != null && tipoSangre != 'Todos')
        ? '?tipo_sangre=${Uri.encodeQueryComponent(tipoSangre)}'
        : '';
    final uri = Uri.parse('$_baseUrl/unidades$query');

    try {
      final response = await _client.get(uri, headers: _jsonHeaders).timeout(_timeout);
      final data = _decodificarRespuesta(response) as List<dynamic>;
      return data
          .map((item) => UnidadSangre.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw BloodBankException(_mensajeConexion(e));
    }
  }

  Future<UnidadSangre> registrarUnidad({
    required String nombreDonante,
    required String tipoSangre,
    required String nombreUbicacion,
    required String fechaExtraccion,
    required String fechaCaducidad,
    int cantidadMl = 200,
  }) async {
    final uri = Uri.parse('$_baseUrl/unidades');
    final extraccionIso = fechaExtraccion.trim().replaceFirst(' ', 'T');

    try {
      final response = await _client
          .post(
            uri,
            headers: _jsonHeaders,
            body: jsonEncode({
              'nombre_donante': nombreDonante.trim(),
              'tipo_sangre': tipoSangre.trim().toUpperCase(),
              'nombre_ubicacion': nombreUbicacion.trim(),
              'fecha_hora_extraccion': extraccionIso,
              'fecha_caducidad': fechaCaducidad.trim(),
              'cantidad_ml': cantidadMl,
            }),
          )
          .timeout(_timeout);
      final data = _decodificarRespuesta(response) as Map<String, dynamic>;
      return UnidadSangre.fromJson(data);
    } catch (e) {
      throw BloodBankException(_mensajeConexion(e));
    }
  }

  Future<UnidadSangre> editarUnidad(
    int id, {
    String? tipoSangre,
    String? nombreDonante,
    String? nombreUbicacion,
    String? fechaExtraccion,
    String? fechaCaducidad,
    int? cantidadMl,
  }) async {
    final uri = Uri.parse('$_baseUrl/unidades/$id');
    final body = <String, dynamic>{};
    if (tipoSangre != null && tipoSangre.trim().isNotEmpty) {
      body['tipo_sangre'] = tipoSangre.trim().toUpperCase();
    }
    if (nombreDonante != null && nombreDonante.trim().isNotEmpty) {
      body['nombre_donante'] = nombreDonante.trim();
    }
    if (nombreUbicacion != null && nombreUbicacion.trim().isNotEmpty) {
      body['nombre_ubicacion'] = nombreUbicacion.trim();
    }
    if (fechaExtraccion != null && fechaExtraccion.trim().isNotEmpty) {
      body['fecha_hora_extraccion'] = fechaExtraccion.trim().replaceFirst(' ', 'T');
    }
    if (fechaCaducidad != null && fechaCaducidad.trim().isNotEmpty) {
      body['fecha_caducidad'] = fechaCaducidad.trim();
    }
    if (cantidadMl != null) {
      body['cantidad_ml'] = cantidadMl;
    }

    try {
      final response = await _client
          .put(uri, headers: _jsonHeaders, body: jsonEncode(body))
          .timeout(_timeout);
      final data = _decodificarRespuesta(response) as Map<String, dynamic>;
      return UnidadSangre.fromJson(data);
    } catch (e) {
      throw BloodBankException(_mensajeConexion(e));
    }
  }

  Future<void> retirarUnidad(int id) async {
    final uri = Uri.parse('$_baseUrl/unidades/$id');
    try {
      final response = await _client.delete(uri, headers: _jsonHeaders).timeout(_timeout);
      _decodificarRespuesta(response);
    } catch (e) {
      throw BloodBankException(_mensajeConexion(e));
    }
  }

  Future<void> eliminarSolicitud(int id) async {
    final uri = Uri.parse('$_baseUrl/solicitudes/$id');
    try {
      final response = await _client.delete(uri, headers: _jsonHeaders).timeout(_timeout);
      _decodificarRespuesta(response);
    } catch (e) {
      throw BloodBankException(_mensajeConexion(e));
    }
  }

  Future<SolicitudSangre> editarSolicitud(
    int id, {
    String? tipoSangre,
    String? centroSalud,
    String? prioridad,
    double? cantidadMl,
  }) async {
    final uri = Uri.parse('$_baseUrl/solicitudes/$id');
    final body = <String, dynamic>{};
    if (tipoSangre != null && tipoSangre.trim().isNotEmpty) {
      body['tipo_sangre'] = tipoSangre.trim().toUpperCase();
    }
    if (centroSalud != null && centroSalud.trim().isNotEmpty) {
      body['centro_salud'] = centroSalud.trim();
    }
    if (prioridad != null && prioridad.trim().isNotEmpty) {
      body['prioridad'] = prioridad.trim();
    }
    if (cantidadMl != null) {
      body['cantidad_ml'] = cantidadMl;
    }

    try {
      final response = await _client
          .put(uri, headers: _jsonHeaders, body: jsonEncode(body))
          .timeout(_timeout);
      final data = _decodificarRespuesta(response) as Map<String, dynamic>;
      return SolicitudSangre.fromJson(data);
    } catch (e) {
      throw BloodBankException(_mensajeConexion(e));
    }
  }

  Future<SolicitudSangre> cambiarEstadoSolicitud(int id, String nuevoEstado) async {
    final uri = Uri.parse('$_baseUrl/solicitudes/$id/estado');
    try {
      final response = await _client
          .patch(
            uri,
            headers: _jsonHeaders,
            body: jsonEncode({'estado': nuevoEstado.trim().toLowerCase()}),
          )
          .timeout(_timeout);
      final data = _decodificarRespuesta(response) as Map<String, dynamic>;
      return SolicitudSangre.fromJson(data);
    } catch (e) {
      throw BloodBankException(_mensajeConexion(e));
    }
  }

  Future<List<String>> obtenerUbicaciones() async {
    final uri = Uri.parse('$_baseUrl/ubicaciones');
    try {
      final response = await _client.get(uri, headers: _jsonHeaders).timeout(_timeout);
      final data = _decodificarRespuesta(response) as List<dynamic>;
      return data
          .map((item) => (item as Map<String, dynamic>)['nombre_ubicacion'].toString())
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<SolicitudSangre>> obtenerSolicitudes({String? estado}) async {
    final query = (estado != null && estado != 'Todas')
        ? '?estado=${Uri.encodeQueryComponent(estado)}'
        : '';
    final uri = Uri.parse('$_baseUrl/solicitudes$query');

    try {
      final response = await _client.get(uri, headers: _jsonHeaders).timeout(_timeout);
      final data = _decodificarRespuesta(response) as List<dynamic>;
      return data
          .map((item) => SolicitudSangre.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw BloodBankException(_mensajeConexion(e));
    }
  }

  Future<SolicitudSangre> crearSolicitud({
    required String tipoSangre,
    required double cantidadMl,
    required String prioridad,
    required String centroSalud,
  }) async {
    final uri = Uri.parse('$_baseUrl/solicitudes');
    try {
      final response = await _client
          .post(
            uri,
            headers: _jsonHeaders,
            body: jsonEncode({
              'tipo_sangre': tipoSangre.trim().toUpperCase(),
              'cantidad_ml': cantidadMl,
              'prioridad': prioridad.trim(),
              'centro_salud': centroSalud.trim(),
            }),
          )
          .timeout(_timeout);
      final data = _decodificarRespuesta(response) as Map<String, dynamic>;
      return SolicitudSangre.fromJson(data);
    } catch (e) {
      throw BloodBankException(_mensajeConexion(e));
    }
  }

  Future<SolicitudSangre> completarSolicitud(int id) async {
    final uri = Uri.parse('$_baseUrl/solicitudes/$id/completar');
    try {
      final response = await _client.patch(uri, headers: _jsonHeaders).timeout(_timeout);
      final data = _decodificarRespuesta(response) as Map<String, dynamic>;
      return SolicitudSangre.fromJson(data);
    } catch (e) {
      throw BloodBankException(_mensajeConexion(e));
    }
  }

  Future<SolicitudSangre> cancelarSolicitud(int id) async {
    final uri = Uri.parse('$_baseUrl/solicitudes/$id/cancelar');
    try {
      final response = await _client.patch(uri, headers: _jsonHeaders).timeout(_timeout);
      final data = _decodificarRespuesta(response) as Map<String, dynamic>;
      return SolicitudSangre.fromJson(data);
    } catch (e) {
      throw BloodBankException(_mensajeConexion(e));
    }
  }
}
