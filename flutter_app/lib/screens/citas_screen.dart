import 'package:flutter/material.dart';
import '../services/cita_service.dart';


// ===========================================================================
// Pestaña "Citas de extracción": listado + botón de creación
// ===========================================================================
class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen> {
  final _citaService = CitaService();
  List<Cita> _citas = [];
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarCitas();
  }

  Future<void> _cargarCitas() async {
    setState(() => _cargando = true);
    try {
      final lista = await _citaService.listarCitas();
      setState(() => _citas = lista);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar citas: $e')),
      );
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _abrirFormulario({Cita? cita}) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CitaFormScreen(citaExistente: cita),
      ),
    );
    if (res == true) _cargarCitas();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Citas de extracción',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _cargarCitas,
            ),
            ElevatedButton.icon(
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add),
              label: const Text('Nueva cita'),
            ),
          ],
        ),
        const SizedBox(height: 15),
        if (_cargando)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_citas.isEmpty)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Text('No hay citas registradas.'),
          )
        else
          ..._citas.map(
                (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () => _abrirFormulario(cita: c),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.all(16),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Donante #${c.idDonante}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${c.fechaHora} — ${c.estado}',
                              style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit, size: 18),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}


// ===========================================================================
// Formulario de creación / edición (pantalla empujada con Navigator)
// ===========================================================================
class CitaFormScreen extends StatefulWidget {
  final Cita? citaExistente;

  const CitaFormScreen({super.key, this.citaExistente});

  bool get esEdicion => citaExistente != null;

  @override
  State<CitaFormScreen> createState() => _CitaFormScreenState();
}

class _CitaFormScreenState extends State<CitaFormScreen> {
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
      _fechaHora =
          DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
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
        SnackBar(
          content: Text(widget.esEdicion ? 'Cita actualizada' : 'Cita creada'),
        ),
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
                  onChanged: (v) =>
                      setState(() => _estado = v ?? 'pendiente'),
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