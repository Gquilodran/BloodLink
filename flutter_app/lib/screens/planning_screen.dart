
import 'package:blood_link/services/cita_service.dart';
import 'package:flutter/material.dart';

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
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: colorHeader,
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
                      color: colorTextoHeader
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatoFecha(fecha),
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
