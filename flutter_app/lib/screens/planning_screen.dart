import 'package:flutter/material.dart';

const List<String> nombresDias = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

/// Lunes de la semana que contiene [fecha], a medianoche.
DateTime lunesDe(DateTime fecha) =>
    DateTime(fecha.year, fecha.month, fecha.day - (fecha.weekday - 1));

/// Suma días según el calendario (evita errores con el cambio de hora).
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
  late DateTime _inicioSemana;

  @override
  void initState() {
    super.initState();
    _inicioSemana = lunesDe(DateTime.now());
  }

  DateTime get _finSemana => sumarDias(_inicioSemana, 6);

  void _moverSemanas(int semanas) {
    setState(() {
      _inicioSemana = sumarDias(_inicioSemana, 7 * semanas);
    });
  }

  void _irAHoy() {
    setState(() {
      _inicioSemana = lunesDe(DateTime.now());
    });
  }

  Widget _barra() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Text(
          'Semana del ${dd(_inicioSemana)} al ${dd(_finSemana)}/${_finSemana.year}',
          key: const Key('titulo-semana'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Semana anterior',
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _moverSemanas(-1),
            ),
            OutlinedButton(
              onPressed: _irAHoy,
              child: const Text('Hoy'),
            ),
            IconButton(
              tooltip: 'Semana siguiente',
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _moverSemanas(1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _columnaDia(int indice) {
    final dia = sumarDias(_inicioSemana, indice);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            nombresDias[indice],
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            dd(dia),
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sin citas ni despachos',
            style: TextStyle(fontSize: 12, color: Colors.black38),
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
        const SizedBox(height: 8),
        const Text(
          'Aquí se mostrarán las citas de extracción y los despachos.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 1050,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _columnaDia(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}