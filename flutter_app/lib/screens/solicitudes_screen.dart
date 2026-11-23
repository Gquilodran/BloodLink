
import 'package:flutter/material.dart';

class SolicitudesScreen extends StatefulWidget {
  const SolicitudesScreen({super.key});

  @override
  State<SolicitudesScreen> createState() =>
      _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pacienteController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _observacionesController = TextEditingController();

  String? _tipoSangre;
  bool _mostrarFormulario = false;

  final List<Map<String, String>> _solicitudes = [];

  final List<String> _tiposSangre = [
    'A+', 'A-', 'B+', 'B-',
    'AB+', 'AB-', 'O+', 'O-',
  ];

  @override
  void dispose() {
    _pacienteController.dispose();
    _cantidadController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  void _registrarSolicitud() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Formulario validado. Registro pendiente de conexión.',
        ),
      ),
    );
  }

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    _pacienteController.clear();
    _cantidadController.clear();
    _observacionesController.clear();

    setState(() {
      _tipoSangre = null;
      _mostrarFormulario = false;
    });
  }

  Widget _campo(
    String titulo,
    TextEditingController controller, {
    bool numerico = false,
    int lineas = 1,
    bool obligatorio = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        maxLines: lineas,
        keyboardType: numerico
            ? TextInputType.number
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: titulo,
          border: const OutlineInputBorder(),
        ),
        validator: (valor) {
          if (obligatorio &&
              (valor == null || valor.trim().isEmpty)) {
            return 'Este campo es obligatorio';
          }

          if (numerico) {
            final numero = int.tryParse(valor ?? '');

            if (numero == null || numero <= 0) {
              return 'Ingrese una cantidad válida';
            }
          }

          return null;
        },
      ),
    );
  }

  Widget _formulario() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nueva solicitud de sangre',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete los datos de la solicitud.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 25),

            _campo(
              'Paciente',
              _pacienteController,
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: DropdownButtonFormField<String>(
                initialValue: _tipoSangre,
                decoration: const InputDecoration(
                  labelText: 'Tipo de sangre requerido',
                  border: OutlineInputBorder(),
                ),
                items: _tiposSangre.map((tipo) {
                  return DropdownMenuItem(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (valor) {
                  setState(() {
                    _tipoSangre = valor;
                  });
                },
                validator: (valor) {
                  if (valor == null) {
                    return 'Seleccione un tipo de sangre';
                  }
                  return null;
                },
              ),
            ),

            _campo(
              'Cantidad de unidades',
              _cantidadController,
              numerico: true,
            ),

            _campo(
              'Observaciones',
              _observacionesController,
              lineas: 3,
              obligatorio: false,
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _registrarSolicitud,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Registrar solicitud'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 17,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: _limpiarFormulario,
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tablaSolicitudes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Solicitudes de sangre',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _mostrarFormulario = true;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Nueva solicitud'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        const Text(
          'Consulte las solicitudes de sangre registradas.',
          style: TextStyle(color: Colors.black54),
        ),

        const SizedBox(height: 25),

        SizedBox(
          width: double.infinity,
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Paciente')),
                  DataColumn(label: Text('Tipo')),
                  DataColumn(label: Text('Cantidad')),
                  DataColumn(label: Text('Estado')),
                ],
                rows: _solicitudes.map((solicitud) {
                  return DataRow(
                    cells: [
                      DataCell(Text(solicitud['id'] ?? '')),
                      DataCell(
                        Text(solicitud['paciente'] ?? ''),
                      ),
                      DataCell(
                        Text(solicitud['tipo'] ?? ''),
                      ),
                      DataCell(
                        Text(solicitud['cantidad'] ?? ''),
                      ),
                      DataCell(
                        Text(solicitud['estado'] ?? ''),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        if (_solicitudes.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'No hay solicitudes cargadas. '
              'Pendiente de conexión con el backend.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_mostrarFormulario) {
      return _formulario();
    }

    return _tablaSolicitudes();
  }
}
