import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/cita.dart';

class CitaService {
  final String _baseUrl = AppConfig.apiUrl;

  Future<List<Cita>> listarCitas() async {
    final resp = await http.get(Uri.parse('$_baseUrl/citas/'));
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as List<dynamic>;
      return data.map((e) => Cita.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Error al listar citas: ${resp.statusCode}');
  }

  Future<Cita> crearCita({
    required int idDonante,
    int? idPersonal,
    required DateTime fechaHora,
    String? observaciones,
  }) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/citas/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_donante': idDonante,
        'id_personal': idPersonal,
        'fecha_hora': fechaHora.toIso8601String(),
        'observaciones': observaciones,
      }),
    );
    if (resp.statusCode == 201) {
      return Cita.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
    }
    throw Exception('Error al crear cita: ${resp.statusCode} - ${resp.body}');
  }

  Future<Cita> editarCita(
      int idCita, {
        int? idPersonal,
        DateTime? fechaHora,
        String? estado,
        String? observaciones,
      }) async {
    final body = <String, dynamic>{};
    if (idPersonal != null) body['id_personal'] = idPersonal;
    if (fechaHora != null) body['fecha_hora'] = fechaHora.toIso8601String();
    if (estado != null) body['estado'] = estado;
    if (observaciones != null) body['observaciones'] = observaciones;

    final resp = await http.put(
      Uri.parse('$_baseUrl/citas/$idCita'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (resp.statusCode == 200) {
      return Cita.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
    }
    throw Exception('Error al editar cita: ${resp.statusCode} - ${resp.body}');
  }

  Future<void> eliminarCita(int idCita) async {
    final resp = await http.delete(Uri.parse('$_baseUrl/citas/$idCita'));
    if (resp.statusCode != 204) {
      throw Exception('Error al eliminar cita: ${resp.statusCode}');
    }
  }
}