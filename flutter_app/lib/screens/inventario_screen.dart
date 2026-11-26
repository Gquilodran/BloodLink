import 'package:flutter/material.dart';
import '../services/blood_bank_service.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final BloodBankService _service = BloodBankService();

  String filtroTipo = 'Todos';
  List<UnidadSangre> unidades = [];
  bool _cargando = true;
  String? _error;

  final List<String> _tiposSangre = const [
    'A+', 'A-', 'B+', 'B-',
    'AB+', 'AB-', 'O+', 'O-',
  ];

  @override
  void initState() {
    super.initState();
    _cargarUnidades();
  }

  Future<void> _cargarUnidades() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultado = await _service.obtenerUnidades();
      if (!mounted) return;
      setState(() {
        unidades = resultado;
        _cargando = false;
      });
    } on BloodBankException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _cargando = false;
      });
    }
  }

  Future<void> _retirarUnidad(UnidadSangre unidad) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirar unidad de sangre'),
        content: Text(
          '¿Confirmar el retiro de la unidad #${unidad.id} (${unidad.tipoSangre}) '
          'ubicada en "${unidad.ubicacion}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await _service.retirarUnidad(unidad.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unidad #${unidad.id} retirada del inventario.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      _cargarUnidades();
    } on BloodBankException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _editarUnidad(UnidadSangre unidad) async {
    final donanteCtrl = TextEditingController(text: unidad.donante);
    final ubicacionCtrl = TextEditingController(text: unidad.ubicacion);
    final caducidadCtrl = TextEditingController(text: unidad.fechaCaducidad);
    String tipoSeleccionado = unidad.tipoSangre;
    final formKey = GlobalKey<FormState>();

    final guardado = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Editar unidad #${unidad.id}'),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _tiposSangre.contains(tipoSeleccionado)
                            ? tipoSeleccionado
                            : _tiposSangre.first,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de sangre',
                          border: OutlineInputBorder(),
                        ),
                        items: _tiposSangre
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (valor) {
                          if (valor != null) {
                            setDialogState(() => tipoSeleccionado = valor);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: donanteCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Donante',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: ubicacionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ubicación',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: caducidadCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Caducidad (YYYY-MM-DD)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || DateTime.tryParse(v.trim()) == null) {
                            return 'Formato válido: YYYY-MM-DD';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (guardado == true && mounted) {
      try {
        await _service.editarUnidad(
          unidad.id,
          tipoSangre: tipoSeleccionado,
          nombreDonante: donanteCtrl.text,
          nombreUbicacion: ubicacionCtrl.text,
          fechaCaducidad: caducidadCtrl.text,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unidad #${unidad.id} actualizada.'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _cargarUnidades();
      } on BloodBankException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }

    donanteCtrl.dispose();
    ubicacionCtrl.dispose();
    caducidadCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = unidades.where((unidad) {
      return filtroTipo == 'Todos' || unidad.tipoSangre == filtroTipo;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Inventario de sangre',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _cargando ? null : _cargarUnidades,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Consulte, edite o retire las unidades de sangre registradas en PostgreSQL.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 25),
        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String>(
            initialValue: filtroTipo,
            decoration: const InputDecoration(
              labelText: 'Tipo de sangre',
              border: OutlineInputBorder(),
            ),
            items: [
              'Todos',
              ..._tiposSangre,
            ].map((tipo) {
              return DropdownMenuItem(
                value: tipo,
                child: Text(tipo),
              );
            }).toList(),
            onChanged: (valor) {
              setState(() {
                filtroTipo = valor ?? 'Todos';
              });
            },
          ),
        ),
        const SizedBox(height: 25),
        if (_cargando)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Card(
            elevation: 0,
            color: const Color(0xFFFEF2F2),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Color(0xFFFECACA)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFB71C1C)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_error!)),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _cargarUnidades,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          )
        else ...[
          SizedBox(
            width: double.infinity,
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Tipo')),
                    DataColumn(label: Text('Donante')),
                    DataColumn(label: Text('Ubicación')),
                    DataColumn(label: Text('Extracción')),
                    DataColumn(label: Text('Caducidad')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: filtradas.map((unidad) {
                    return DataRow(
                      cells: [
                        DataCell(Text('#${unidad.id}')),
                        DataCell(
                          Text(
                            unidad.tipoSangre,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(Text(unidad.donante)),
                        DataCell(Text(unidad.ubicacion)),
                        DataCell(Text(unidad.fechaExtraccion)),
                        DataCell(Text(unidad.fechaCaducidad)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Editar unidad',
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _editarUnidad(unidad),
                              ),
                              IconButton(
                                tooltip: 'Retirar del inventario',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Color(0xFFB71C1C),
                                ),
                                onPressed: () => _retirarUnidad(unidad),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          if (filtradas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No hay unidades registradas para el filtro seleccionado.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
        ],
      ],
    );
  }
}
