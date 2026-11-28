
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

String _dos(int n) => n.toString().padLeft(2, '0');

String dd(DateTime d) => '${_dos(d.day)}/${_dos(d.month)}';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  static const rojo = Color(0xFFB71C1C);

  late DateTime _inicioSemana;
  DateTime _fechaSeleccionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    _inicioSemana = lunesDe(_fechaSeleccionada);
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
          'Semana del ${dd(_inicioSemana)} '
          'al ${dd(_finSemana)}/${_finSemana.year}',
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
    final dia = sumarDias(_inicioSemana, indice);

    final seleccionado = DateUtils.isSameDay(
      dia, _fechaSeleccionada,
    );

    return Container(
      height: 420,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: seleccionado
              ? rojo
              : const Color(0xFFE5E7EB),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: seleccionado
                ? rojo
                : const Color(0xFFF3F4F6),
            child: Column(
              children: [
                Text(
                  nombresDias[indice],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: seleccionado
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  dd(dia),
                  style: TextStyle(
                    color: seleccionado
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          child: _columnaDia(i),
                        ),
                      ),
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
