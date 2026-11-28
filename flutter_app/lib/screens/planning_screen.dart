
import 'package:flutter/material.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  late DateTime _inicioSemana;

  final List<String> _dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _inicioSemana = _lunesDe(DateTime.now());
  }

  DateTime _lunesDe(DateTime fecha) {
    return DateTime(
      fecha.year,
      fecha.month,
      fecha.day - fecha.weekday + 1,
    );
  }

  DateTime _sumarDias(DateTime fecha, int dias) {
    return DateTime(fecha.year, fecha.month, fecha.day + dias);
  }

  String _formatoFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}';
  }

  void _cambiarSemana(int semanas) {
    setState(() {
      _inicioSemana = _sumarDias(_inicioSemana, semanas * 7);
    });
  }

  void _irAHoy() {
    setState(() {
      _inicioSemana = _lunesDe(DateTime.now());
    });
  }

  Widget _columnaDia(int indice) {
    final fecha = _sumarDias(_inicioSemana, indice);
    final esHoy = DateUtils.isSameDay(fecha, DateTime.now());

    return Expanded(
      child: Container(
        height: 450,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: esHoy
                ? const Color(0xFFB71C1C)
                : const Color(0xFFE5E7EB),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: esHoy
                    ? const Color(0xFFB71C1C)
                    : const Color(0xFFF3F4F6),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(7),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _dias[indice],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: esHoy ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _formatoFecha(fecha),
                    style: TextStyle(
                      color: esHoy ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finSemana = _sumarDias(_inicioSemana, 6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Semana del ${_formatoFecha(_inicioSemana)} '
              'al ${_formatoFecha(finSemana)}/${finSemana.year}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              tooltip: 'Semana anterior',
              onPressed: () => _cambiarSemana(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            OutlinedButton(
              onPressed: _irAHoy,
              child: const Text('Hoy'),
            ),
            IconButton(
              tooltip: 'Semana siguiente',
              onPressed: () => _cambiarSemana(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: constraints.maxWidth < 850
                    ? 850
                    : constraints.maxWidth,
                child: Row(
                  children: List.generate(7, _columnaDia),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
