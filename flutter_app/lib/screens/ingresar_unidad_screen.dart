
import 'package:flutter/material.dart';

class IngresarUnidadScreen extends StatefulWidget {
  const IngresarUnidadScreen({super.key});

  @override
  State<IngresarUnidadScreen> createState() =>
      _IngresarUnidadScreenState();
}

class _IngresarUnidadScreenState
    extends State<IngresarUnidadScreen> {
  final _formKey = GlobalKey<FormState>();

  final _donanteController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final _extraccionController = TextEditingController();
  final _caducidadController = TextEditingController();

  String? _tipoSangre;

  final tiposSangre = [
    'A+', 'A-', 'B+', 'B-',
    'AB+', 'AB-', 'O+', 'O-',
  ];

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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        readOnly: fecha,
        decoration: InputDecoration(
          labelText: titulo,
          border: const OutlineInputBorder(),
          suffixIcon: fecha
              ? const Icon(Icons.calendar_today_outlined)
              : null,
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

  void _registrar() {
    if (!_formKey.currentState!.validate()) return;

    final extraccion =
        DateTime.tryParse(_extraccionController.text);
    final caducidad =
        DateTime.tryParse(_caducidadController.text);

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

    // Pendiente: conectar el formulario con el backend.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Formulario validado. Registro pendiente de conexión.',
        ),
      ),
    );
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
              'Complete los datos de la nueva unidad.',
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

            _campo('Ubicación', _ubicacionController),

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
                  onPressed: _registrar,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Registrar unidad'),
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
                  onPressed: () {
                    _formKey.currentState?.reset();
                    _donanteController.clear();
                    _ubicacionController.clear();
                    _extraccionController.clear();
                    _caducidadController.clear();
                    setState(() => _tipoSangre = null);
                  },
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
