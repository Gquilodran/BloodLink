import 'package:flutter/material.dart';
import '../models/cita.dart';
import '../services/cita_service.dart';

class CitasScreen extends StatefulWidget {
  final Cita? citaExistente;

  const CitasScreen({super.key, this.citaExistente});

  bool get esEdicion => citaExistente != null;

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _citaService = CitaService();

  final _idDonanteCtrl = TextEditingController();
  final _idPersonalCtrl = TextEditingController();
  final _observacionesCtrl = TextEditingController();

  DateTime? _fechaHora;
  String _estado = 'pendiente';
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    if (widget.citaExistente != null) {
      final c = widget.citaExistente!;
      _idDonanteCtrl.text = c.idDonante.toString();
      _idPersonalCtrl.text = c.idPersonal?.toString() ?? '';
      _observacionesCtrl.text = c.observaciones ?? '';
      _fechaHora = c.fechaHora;
      _estado = c.estado;
    }
  }

  @override
  void dispose() {
    _idDonanteCtrl.dispose();
    _idPersonalCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFechaHora() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaHora ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (fecha == null) return;
    if (!mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fechaHora ?? DateTime.now()),
    );
    if (hora == null) return;
    setState(() {
      _fechaHora = DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaHora == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar fecha y hora')),
      );
      return;
    }
    setState(() => _guardando = true);
    try {
      if (widget.esEdicion) {
        await _citaService.editarCita(
          widget.citaExistente!.idCita,
          idPersonal: _idPersonalCtrl.text.isEmpty
              ? null
              : int.parse(_idPersonalCtrl.text),
          fechaHora: _fechaHora,
          estado: _estado,
          observaciones: _observacionesCtrl.text.isEmpty
              ? null
              : _observacionesCtrl.text,
        );
      } else {
        await _citaService.crearCita(
          idDonante: int.parse(_idDonanteCtrl.text),
          idPersonal: _idPersonalCtrl.text.isEmpty
              ? null
              : int.parse(_idPersonalCtrl.text),
          fechaHora: _fechaHora!,
          observaciones: _observacionesCtrl.text.isEmpty
              ? null
              : _observacionesCtrl.text,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.esEdicion ? 'Cita actualizada' : 'Cita creada')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esEdicion ? 'Editar cita' : 'Nueva cita'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _idDonanteCtrl,
                decoration: const InputDecoration(labelText: 'ID del donante'),
                keyboardType: TextInputType.number,
                enabled: !widget.esEdicion,
                validator: (v) =>
                (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _idPersonalCtrl,
                decoration: const InputDecoration(
                  labelText: 'ID del personal de salud (opcional)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Fecha y hora'),
                subtitle: Text(_fechaHora?.toString() ?? 'Sin seleccionar'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _seleccionarFechaHora,
              ),
              const SizedBox(height: 12),
              if (widget.esEdicion)
                DropdownButtonFormField<String>(
                  value: _estado,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                    DropdownMenuItem(value: 'completada', child: Text('Completada')),
                    DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
                  ],
                  onChanged: (v) => setState(() => _estado = v ?? 'pendiente'),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observacionesCtrl,
                decoration: const InputDecoration(labelText: 'Observaciones'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const CircularProgressIndicator()
                    : Text(widget.esEdicion ? 'Guardar cambios' : 'Crear cita'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}