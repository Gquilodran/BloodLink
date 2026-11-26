import 'package:flutter/material.dart';
import '../services/blood_bank_service.dart';

class IngresarUnidadScreen extends StatefulWidget {
  const IngresarUnidadScreen({super.key});

  @override
  State<IngresarUnidadScreen> createState() => _IngresarUnidadScreenState();
}

class _IngresarUnidadScreenState extends State<IngresarUnidadScreen> {
  final _formKey = GlobalKey<FormState>();
  final BloodBankService _service = BloodBankService();

  final _donanteController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _extraccionController = TextEditingController();
  final _caducidadController = TextEditingController();

  String? _tipoSangre;
  bool _guardando = false;
  List<String> _ubicacionesDisponibles = [];

  final tiposSangre = [
    'A+', 'A-', 'B+', 'B-',
    'AB+', 'AB-', 'O+', 'O-',
  ];

  @override
  void initState() {
    super.initState();
    _cargarUbicaciones();
  }

  Future<void> _cargarUbicaciones() async {
    final lista = await _service.obtenerUbicaciones();
    if (!mounted) return;
    setState(() {
      _ubicacionesDisponibles = lista;
    });
  }

  @override
  void dispose() {
    _donanteController.dispose();
    _ubicacionController.dispose();
    _extraccionController.dispose();
    _caducidadController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha({
    required TextEditingController controller,
    bool incluirHora = false,
  }) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (fecha == null || !mounted) return;

    if (incluirHora) {
      final hora = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (hora == null || !mounted) return;

      controller.text =
          '${fecha.year}-${_dos(fecha.month)}-${_dos(fecha.day)} '
          '${_dos(hora.hour)}:${_dos(hora.minute)}';
    } else {
      controller.text =
          '${fecha.year}-${_dos(fecha.month)}-${_dos(fecha.day)}';
    }
  }

  String _dos(int numero) => numero.toString().padLeft(2, '0');

  Widget _campo(
    String titulo,
    TextEditingController controller, {
    bool fecha = false,
    bool incluirHora = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        readOnly: fecha,
        decoration: InputDecoration(
          labelText: titulo,
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon ??
              (fecha ? const Icon(Icons.calendar_today_outlined) : null),
        ),
        onTap: fecha
            ? () => _seleccionarFecha(
                  controller: controller,
                  incluirHora: incluirHora,
                )
            : null,
        validator: (valor) {
          if (valor == null || valor.trim().isEmpty) {
            return 'Este campo es obligatorio';
          }
          return null;
        },
      ),
    );
  }

  void _limpiar() {
    _formKey.currentState?.reset();
    _donanteController.clear();
    _ubicacionController.clear();
    _extraccionController.clear();
    _caducidadController.clear();
    setState(() => _tipoSangre = null);
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;

    final extraccion = DateTime.tryParse(_extraccionController.text);
    final caducidad = DateTime.tryParse(_caducidadController.text);

    if (extraccion == null || caducidad == null) return;

    if (caducidad.isBefore(
      DateTime(extraccion.year, extraccion.month, extraccion.day),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La caducidad no puede ser anterior a la extracción.',
          ),
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final creada = await _service.registrarUnidad(
        nombreDonante: _donanteController.text,
        tipoSangre: _tipoSangre!,
        nombreUbicacion: _ubicacionController.text,
        fechaExtraccion: _extraccionController.text,
        fechaCaducidad: _caducidadController.text,
      );

      if (!mounted) return;
      _limpiar();
      _cargarUbicaciones();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unidad #${creada.id} (${creada.tipoSangre}) registrada exitosamente.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } on BloodBankException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registro de unidad de sangre',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete los datos de la nueva unidad para almacenarla en PostgreSQL.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 25),
            _campo('Nombre del donante', _donanteController),
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: DropdownButtonFormField<String>(
                initialValue: _tipoSangre,
                decoration: const InputDecoration(
                  labelText: 'Tipo de sangre',
                  border: OutlineInputBorder(),
                ),
                items: tiposSangre.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (valor) {
                  setState(() => _tipoSangre = valor);
                },
                validator: (valor) =>
                    valor == null ? 'Seleccione un tipo' : null,
              ),
            ),
            _campo(
              'Ubicación',
              _ubicacionController,
              suffixIcon: _ubicacionesDisponibles.isEmpty
                  ? null
                  : PopupMenuButton<String>(
                      tooltip: 'Elegir ubicación existente',
                      icon: const Icon(Icons.arrow_drop_down),
                      onSelected: (valor) {
                        _ubicacionController.text = valor;
                      },
                      itemBuilder: (context) => _ubicacionesDisponibles
                          .map(
                            (u) => PopupMenuItem<String>(
                              value: u,
                              child: Text(u),
                            ),
                          )
                          .toList(),
                    ),
            ),
            _campo(
              'Fecha y hora de extracción',
              _extraccionController,
              fecha: true,
              incluirHora: true,
            ),
            _campo(
              'Fecha de caducidad',
              _caducidadController,
              fecha: true,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _guardando ? null : _registrar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_guardando ? 'Registrando...' : 'Registrar unidad'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _guardando ? null : _limpiar,
                  child: const Text('Limpiar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
