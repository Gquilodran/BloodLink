import 'package:flutter/material.dart';
import '../services/blood_bank_service.dart';

enum FiltroVigencia { vigentes, caducadas }

class InventarioScreen extends StatefulWidget {
  final FiltroVigencia initialFiltro;
  final VoidCallback? onInventarioChanged;

  const InventarioScreen({
    super.key,
    this.initialFiltro = FiltroVigencia.vigentes,
    this.onInventarioChanged,
  });

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  final BloodBankService _service = BloodBankService();

  late FiltroVigencia _filtroVigencia;
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
    _filtroVigencia = widget.initialFiltro;
    _cargarUnidades();
  }

  @override
  void didUpdateWidget(covariant InventarioScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFiltro != widget.initialFiltro) {
      setState(() {
        _filtroVigencia = widget.initialFiltro;
      });
    }
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
      widget.onInventarioChanged?.call();
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
    final cantidadCtrl =
        TextEditingController(text: unidad.cantidadMl.toString());
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
                        controller: cantidadCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Volumen (ml)',
                          suffixText: 'ml',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final texto = v?.trim() ?? '';
                          if (texto.isEmpty) return 'Campo obligatorio';
                          final ml = int.tryParse(texto);
                          if (ml == null || ml <= 0 || ml > 500) {
                            return 'Ingrese un entero entre 1 y 500';
                          }
                          return null;
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
          cantidadMl: int.parse(cantidadCtrl.text.trim()),
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
    cantidadCtrl.dispose();
  }

  Widget _badgeVigencia(UnidadSangre unidad) {
    if (unidad.estaVencida) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: const Text(
          'Caducada',
          style: TextStyle(
            color: Color(0xFF991B1B),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (unidad.venceHoy) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: const Text(
          'Vence hoy',
          style: TextStyle(
            color: Color(0xFF92400E),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final dias = unidad.diasRestantes;
    if (dias != null && dias <= 3) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDD5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFDBA74)),
        ),
        child: Text(
          'Por vencer ($dias d)',
          style: const TextStyle(
            color: Color(0xFF9A3412),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    final texto = dias != null ? 'Vigente ($dias d)' : 'Vigente';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: Color(0xFF166534),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalVigentes = unidades.where((u) => !u.estaVencida).length;
    final totalCaducadas = unidades.where((u) => u.estaVencida).length;

    final filtradas = unidades.where((unidad) {
      final coincideVigencia = _filtroVigencia == FiltroVigencia.caducadas
          ? unidad.estaVencida
          : !unidad.estaVencida;
      final coincideTipo =
          filtroTipo == 'Todos' || unidad.tipoSangre == filtroTipo;
      return coincideVigencia && coincideTipo;
    }).toList();

    filtradas.sort((a, b) {
      if (_filtroVigencia == FiltroVigencia.vigentes) {
        return a.fechaCaducidad.compareTo(b.fechaCaducidad);
      }
      return b.fechaCaducidad.compareTo(a.fechaCaducidad);
    });

    final esVistaCaducadas = _filtroVigencia == FiltroVigencia.caducadas;

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
        const SizedBox(height: 20),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<FiltroVigencia>(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return esVistaCaducadas
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFDCFCE7);
                  }
                  return Colors.white;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return esVistaCaducadas
                        ? const Color(0xFF991B1B)
                        : const Color(0xFF166534);
                  }
                  return Colors.black87;
                }),
              ),
              segments: [
                ButtonSegment<FiltroVigencia>(
                  value: FiltroVigencia.vigentes,
                  icon: const Icon(Icons.verified_outlined, size: 18),
                  label: Text('Vigentes ($totalVigentes)'),
                ),
                ButtonSegment<FiltroVigencia>(
                  value: FiltroVigencia.caducadas,
                  icon: const Icon(Icons.warning_amber_rounded, size: 18),
                  label: Text('Caducadas ($totalCaducadas)'),
                ),
              ],
              selected: {_filtroVigencia},
              onSelectionChanged: (seleccion) {
                setState(() {
                  _filtroVigencia = seleccion.first;
                });
              },
            ),
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
          ],
        ),
        if (esVistaCaducadas) ...[
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              border: Border.all(color: const Color(0xFFFCA5A5)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.report_problem_outlined, color: Color(0xFFB71C1C)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Unidades caducadas: no aptas para uso clínico. Retire estas bolsas del inventario.',
                    style: TextStyle(
                      color: Color(0xFF991B1B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
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
                side: BorderSide(
                  color: esVistaCaducadas
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFFE5E7EB),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Tipo')),
                    DataColumn(label: Text('Volumen')),
                    DataColumn(label: Text('Donante')),
                    DataColumn(label: Text('Ubicación')),
                    DataColumn(label: Text('Extracción')),
                    DataColumn(label: Text('Caducidad')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: filtradas.map((unidad) {
                    return DataRow(
                      color: unidad.estaVencida
                          ? const WidgetStatePropertyAll(Color(0xFFFFF5F5))
                          : null,
                      cells: [
                        DataCell(Text('#${unidad.id}')),
                        DataCell(
                          Text(
                            unidad.tipoSangre,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(Text('${unidad.cantidadMl} ml')),
                        DataCell(Text(unidad.donante)),
                        DataCell(Text(unidad.ubicacion)),
                        DataCell(Text(unidad.fechaExtraccion)),
                        DataCell(
                          Text(
                            unidad.fechaCaducidad,
                            style: TextStyle(
                              color: unidad.estaVencida
                                  ? const Color(0xFFB71C1C)
                                  : Colors.black87,
                              fontWeight: unidad.estaVencida
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        DataCell(_badgeVigencia(unidad)),
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                esVistaCaducadas
                    ? 'No hay unidades caducadas registradas.'
                    : 'No hay unidades vigentes para el filtro seleccionado.',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
        ],
      ],
    );
  }
}
