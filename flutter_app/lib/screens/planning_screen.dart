
import 'package:blood_link/services/cita_service.dart';
import 'package:flutter/material.dart';

const List<String> nombresDias = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves',
  'Viernes', 'Sábado', 'Domingo',
];

const List<String> nombresMeses = [
  'Enero', 'Febrero', 'Marzo', 'Abril',
  'Mayo', 'Junio', 'Julio', 'Agosto',
  'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

DateTime lunesDe(DateTime fecha) =>
    DateTime(fecha.year, fecha.month, fecha.day - fecha.weekday + 1);

DateTime sumarDias(DateTime fecha, int dias) =>
    DateTime(fecha.year, fecha.month, fecha.day + dias);

String dos(int n) => n.toString().padLeft(2, '0');

String formatoFecha(DateTime d) => '${dos(d.day)}/${dos(d.month)}';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  late DateTime _inicioSemana;
  final CitaService _citaService = CitaService();
  List<Cita> _citas = [];
  bool _cargando = true;
  DateTime _fechaSeleccionada = DateTime.now();
  static const rojo = Color(0xFFB71C1C);

  @override
  void initState() {
    super.initState();
    _inicioSemana = lunesDe(_fechaSeleccionada);
    _cargarCitas();
  }

  Future<void> _cargarCitas() async {
  //Para testear la parte gráfica por ahora, quitar los /**/
  /*await Future.delayed(const Duration(milliseconds: 300));
    final ahora = DateTime.now();

    if (!mounted) return;
    setState(() {
      _citas = [
        Cita(
          idCita: 101,
          idDonante: 12,
          idPersonal: 3,
          fechaHora: DateTime(ahora.year, ahora.month, ahora.day, 10, 30),
          estado: 'PROGRAMADA',
          observaciones: 'Donación de sangre',
        ),
        Cita(
          idCita: 102,
          idDonante: 45,
          fechaHora: DateTime(ahora.year, ahora.month, ahora.day + 2, 15, 0),
          estado: 'CONFIRMADA',
        ),
        Cita(
          idCita: 103,
          idDonante: 99,
          fechaHora: DateTime(ahora.year, ahora.month, ahora.day, 15, 0),
          estado: 'CONFIRMADA'
        )
      ];
      _cargando = false;
    });
    return; */

    try {
      final citas = await _citaService.listarCitas();
      if (!mounted) return;

      setState(() => _citas = citas);
    } catch (e) {
      if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar citas: $e')),
        );
    } finally {
      setState(() => _cargando = false);
    }
  }

  List<Cita> _citasDelDia(DateTime fecha) {
    final citasDelDia = _citas
        .where((dia) => DateUtils.isSameDay(dia.fechaHora.toLocal(), fecha))
        .toList();
    citasDelDia.sort((a, b) => a.fechaHora.compareTo(b.fechaHora));
    return citasDelDia;
  }

  String _formatoHora(DateTime fecha) {
    final local = fecha.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  DateTime get _finSemana => sumarDias(_inicioSemana, 6);

  void _seleccionarFecha(DateTime fecha) {
    setState(() {
      _fechaSeleccionada = fecha;
      _inicioSemana = lunesDe(fecha);
    });
  }

  void _moverSemanas(int semanas) {
    _seleccionarFecha(
      sumarDias(_fechaSeleccionada, semanas * 7),
    );
  }

  void _irAHoy() {
    _seleccionarFecha(DateTime.now());
  }

  Future<void> _abrirCalendario() async {
    DateTime mes = DateTime(
      _fechaSeleccionada.year,
      _fechaSeleccionada.month,
    );

    final resultado = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, actualizar) {
            final primerDia = DateTime(mes.year, mes.month, 1);
            final inicio = lunesDe(primerDia);

            final diasMes = DateTime(
              mes.year, mes.month + 1, 0,
            ).day;

            final semanas =
                ((primerDia.weekday - 1 + diasMes) / 7).ceil();

            return AlertDialog(
              title: const Text('Calendario'),
              content: SizedBox(
                width: 490,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Mes anterior',
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              actualizar(() {
                                mes = DateTime(
                                  mes.year, mes.month - 1,
                                );
                              });
                            },
                          ),
                          Expanded(
                            child: Text(
                              '${nombresMeses[mes.month - 1]} '
                              '${mes.year}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Mes siguiente',
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              actualizar(() {
                                mes = DateTime(
                                  mes.year, mes.month + 1,
                                );
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          for (final nombre in [
                            'Sem.', 'Lun', 'Mar', 'Mié',
                            'Jue', 'Vie', 'Sáb', 'Dom',
                          ])
                            Expanded(
                              child: Text(
                                nombre,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (int s = 0; s < semanas; s++)
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: rojo,
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () {
                                  Navigator.pop(
                                    context,
                                    sumarDias(inicio, s * 7),
                                  );
                                },
                                child: Text('S${s + 1}'),
                              ),
                            ),
                            for (int d = 0; d < 7; d++)
                              Expanded(
                                child: _diaCalendario(
                                  context,
                                  sumarDias(inicio, s * 7 + d),
                                  mes,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: rojo,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(context, DateTime.now());
                  },
                  child: const Text('Ir a hoy'),
                ),
              ],
            );
          },
        );
      },
    );

    if (resultado != null && mounted) {
      _seleccionarFecha(resultado);
    }
  }

  Widget _diaCalendario(
    BuildContext context,
    DateTime fecha,
    DateTime mes,
  ) {
    final seleccionado = DateUtils.isSameDay(
      fecha, _fechaSeleccionada,
    );

    final mismaSemana = DateUtils.isSameDay(
      lunesDe(fecha), _inicioSemana,
    );

    final esHoy = DateUtils.isSameDay(fecha, DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: seleccionado
            ? rojo
            : mismaSemana
                ? const Color(0xFFFEE2E2)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => Navigator.pop(context, fecha),
          child: Container(
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: esHoy
                  ? Border.all(color: rojo)
                  : null,
            ),
            child: Text(
              '${fecha.day}',
              style: TextStyle(
                color: seleccionado
                    ? Colors.white
                    : fecha.month == mes.month
                        ? Colors.black87
                        : Colors.black26,
                fontWeight: esHoy || seleccionado
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _barra() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Semana del ${formatoFecha(_inicioSemana)} '
          'al ${formatoFecha(_finSemana)}/${_finSemana.year}',
          key: const Key('titulo-semana'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          tooltip: 'Semana anterior',
          onPressed: () => _moverSemanas(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        OutlinedButton(
          onPressed: _irAHoy,
          child: const Text('Hoy'),
        ),
        IconButton(
          tooltip: 'Semana siguiente',
          onPressed: () => _moverSemanas(1),
          icon: const Icon(Icons.chevron_right),
        ),
        ElevatedButton.icon(
          onPressed: _abrirCalendario,
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('Calendario'),
          style: ElevatedButton.styleFrom(
            backgroundColor: rojo,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _columnaDia(int indice) {
    final fecha = sumarDias(_inicioSemana, indice);
    final esHoy = DateUtils.isSameDay(fecha, DateTime.now());
    final citasDia = _citasDelDia(fecha);
    final tieneCitas = citasDia.isNotEmpty;

    final Color colorBorde = esHoy
        ? const Color(0xFFB71C1C)
        : tieneCitas
            ? const Color(0xFFE53935)
            : const Color(0xFFE5E7EB);
    
    final Color colorHeader = esHoy
        ? const Color(0xFFB71C1C)
        : tieneCitas
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFF3F4F6);
    
    final Color colorTextoHeader = esHoy
        ? Colors.white
        : tieneCitas
            ? const Color(0xFFB71C1C)
            : Colors.black87;

    return Expanded(
      child: Container(
        height: 450,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: tieneCitas && !esHoy ? const Color(0xFFFFF8F8) : Colors.white,
          border: Border.all(
            color: colorBorde,
            width: (esHoy || tieneCitas) ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorHeader,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    nombresDias[indice],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorTextoHeader
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        formatoFecha(fecha),
                        style: TextStyle(
                          color: esHoy ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      if (tieneCitas) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: esHoy
                                ? Colors.white
                                : const Color(0xFFB71C1C),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${citasDia.length}",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: esHoy
                                  ? const Color(0xFFB71C1C)
                                  : Colors.white,
                            ),
                          ),
                        )
                      ]
                    ],
                  )
                ],
              ),
            ),

            Expanded(
              child: _cargando
                  ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : ListView.builder(
                    padding: const EdgeInsets.all(6),
                    itemCount: citasDia.length,
                    itemBuilder: (context, i) {
                      final cita = citasDia[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFEF9A9A),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_formatoHora(cita.fechaHora)} • #${cita.idCita}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB71C1C),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Donante: ${cita.idDonante}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              cita.estado,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  )
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _barra(),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: constraints.maxWidth < 950
                    ? 950
                    : constraints.maxWidth,
                child: Row(
                  children: [
                    for (int i = 0; i < 7; i++)
                      _columnaDia(i)
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
