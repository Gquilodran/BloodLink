import 'package:flutter/material.dart';
import '../services/blood_bank_service.dart';

class SolicitudesScreen extends StatefulWidget {
  const SolicitudesScreen({super.key});

  @override
  State<SolicitudesScreen> createState() => _SolicitudesScreenState();
}

class _SolicitudesScreenState extends State<SolicitudesScreen> {
  final _formKey = GlobalKey<FormState>();
  final BloodBankService _service = BloodBankService();

  final _centroController = TextEditingController();
  final _cantidadController = TextEditingController();

  String? _tipoSangre;
  String? _prioridad;
  String _filtroEstado = 'Todas';
  bool _mostrarFormulario = false;
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  List<SolicitudSangre> _solicitudes = [];

  final List<String> _tiposSangre = const [
    'A+', 'A-', 'B+', 'B-',
    'AB+', 'AB-', 'O+', 'O-',
  ];

  final List<String> _prioridades = const [
    'Baja',
    'Media',
    'Alta',
    'Urgencia Vital',
  ];

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  @override
  void dispose() {
    _centroController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultado = await _service.obtenerSolicitudes();
      if (!mounted) return;
      setState(() {
        _solicitudes = resultado;
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

  Future<void> _registrarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;

    final cantidad = double.tryParse(_cantidadController.text.trim());
    if (cantidad == null || cantidad <= 0) return;

    setState(() => _guardando = true);

    try {
      final creada = await _service.crearSolicitud(
        tipoSangre: _tipoSangre!,
        cantidadMl: cantidad,
        prioridad: _prioridad!,
        centroSalud: _centroController.text,
      );

      if (!mounted) return;
      _limpiarFormulario();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Solicitud #${creada.id} (${creada.tipoSangre}, ${creada.cantidadMl.toStringAsFixed(0)} ml) registrada.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      _cargarSolicitudes();
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

  Future<void> _cambiarEstado(SolicitudSangre solicitud, bool completar) async {
    final accion = completar ? 'completar' : 'cancelar';
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(completar ? 'Completar solicitud' : 'Cancelar solicitud'),
        content: Text(
          '¿Desea $accion la solicitud #${solicitud.id} (${solicitud.tipoSangre} - '
          '${solicitud.cantidadMl.toStringAsFixed(0)} ml) de "${solicitud.centroSalud}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  completar ? Colors.green.shade700 : const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
            ),
            child: Text(completar ? 'Completar' : 'Cancelar solicitud'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      if (completar) {
        await _service.completarSolicitud(solicitud.id);
      } else {
        await _service.cancelarSolicitud(solicitud.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Solicitud #${solicitud.id} marcada como '
            '${completar ? 'completada' : 'cancelada'}.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      _cargarSolicitudes();
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

  void _limpiarFormulario() {
    _formKey.currentState?.reset();
    _centroController.clear();
    _cantidadController.clear();

    setState(() {
      _tipoSangre = null;
      _prioridad = null;
      _mostrarFormulario = false;
    });
  }

  Widget _campo(
    String titulo,
    TextEditingController controller, {
    bool numerico = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        keyboardType: numerico ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: titulo,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: (valor) {
          if (valor == null || valor.trim().isEmpty) {
            return 'Este campo es obligatorio';
          }

          if (numerico) {
            final numero = double.tryParse(valor.trim());
            if (numero == null || numero <= 0) {
              return 'Ingrese una cantidad válida mayor a 0';
            }
          }

          return null;
        },
      ),
    );
  }

  Widget _badgeEstado(String estado) {
    Color bg;
    Color fg;
    switch (estado.toLowerCase()) {
      case 'completada':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF166534);
        break;
      case 'cancelada':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
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
              'Centro de salud / Servicio solicitante',
              _centroController,
              hint: 'Ej. Hospital Clínico Regional',
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
              'Cantidad (ml)',
              _cantidadController,
              numerico: true,
              hint: 'Ej. 450',
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: DropdownButtonFormField<String>(
                initialValue: _prioridad,
                decoration: const InputDecoration(
                  labelText: 'Prioridad',
                  border: OutlineInputBorder(),
                ),
                items: _prioridades.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(p),
                  );
                }).toList(),
                onChanged: (valor) {
                  setState(() {
                    _prioridad = valor;
                  });
                },
                validator: (valor) {
                  if (valor == null) {
                    return 'Seleccione una prioridad';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _guardando ? null : _registrarSolicitud,
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
                  label: Text(_guardando ? 'Registrando...' : 'Registrar solicitud'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 17,
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: _guardando ? null : _limpiarFormulario,
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
    final filtradas = _solicitudes.where((s) {
      return _filtroEstado == 'Todas' || s.estado == _filtroEstado;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            const Text(
              'Solicitudes de sangre',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: _cargando ? null : _cargarSolicitudes,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualizar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _mostrarFormulario = true;
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva solicitud'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Consulte y gestione las solicitudes de sangre registradas en PostgreSQL.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            initialValue: _filtroEstado,
            decoration: const InputDecoration(
              labelText: 'Filtrar por estado',
              border: OutlineInputBorder(),
            ),
            items: const ['Todas', 'pendiente', 'completada', 'cancelada']
                .map(
                  (estado) => DropdownMenuItem(
                    value: estado,
                    child: Text(estado),
                  ),
                )
                .toList(),
            onChanged: (valor) {
              setState(() {
                _filtroEstado = valor ?? 'Todas';
              });
            },
          ),
        ),
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
                    onPressed: _cargarSolicitudes,
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
                    DataColumn(label: Text('Centro de salud')),
                    DataColumn(label: Text('Tipo')),
                    DataColumn(label: Text('Cantidad (ml)')),
                    DataColumn(label: Text('Prioridad')),
                    DataColumn(label: Text('Fecha')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: filtradas.map((solicitud) {
                    final esPendiente = solicitud.estado == 'pendiente';
                    return DataRow(
                      cells: [
                        DataCell(Text('#${solicitud.id}')),
                        DataCell(Text(solicitud.centroSalud)),
                        DataCell(
                          Text(
                            solicitud.tipoSangre,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(Text('${solicitud.cantidadMl.toStringAsFixed(0)} ml')),
                        DataCell(Text(solicitud.prioridad)),
                        DataCell(Text(solicitud.fechaSolicitud)),
                        DataCell(_badgeEstado(solicitud.estado)),
                        DataCell(
                          esPendiente
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Marcar como completada',
                                      icon: Icon(
                                        Icons.check_circle_outline,
                                        size: 20,
                                        color: Colors.green.shade700,
                                      ),
                                      onPressed: () => _cambiarEstado(solicitud, true),
                                    ),
                                    IconButton(
                                      tooltip: 'Cancelar solicitud',
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        size: 20,
                                        color: Color(0xFFB71C1C),
                                      ),
                                      onPressed: () => _cambiarEstado(solicitud, false),
                                    ),
                                  ],
                                )
                              : Text(
                                  solicitud.fechaCompletada ?? '-',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
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
                'No hay solicitudes registradas para el filtro seleccionado.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
        ],
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
