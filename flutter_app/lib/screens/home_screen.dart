import 'package:flutter/material.dart';
import '../services/blood_bank_service.dart';
import '../widgets/sidebar.dart';
import 'inventario_screen.dart';
import 'ingresar_unidad_screen.dart';
import 'solicitudes_screen.dart';
import 'planning_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BloodBankService _service = BloodBankService();

  int selectedIndex = 0;
  FiltroVigencia _inventarioFiltro = FiltroVigencia.vigentes;
  AlertasVencimiento? _alertas;
  bool _alertaCerrada = false;

  // NUEVO: se añade el título para el índice 4
  final titulos = [
    'Inicio',
    'Inventario de sangre',
    'Ingresar unidad de sangre',
    'Solicitudes de sangre',
    'Planning semanal',
  ];

  @override
  void initState() {
    super.initState();
    _cargarAlertas();
  }

  Future<void> _cargarAlertas() async {
    try {
      final resultado = await _service.obtenerAlertasVencimiento();
      if (!mounted) return;
      setState(() {
        _alertas = resultado;
      });
    } catch (_) {
      // Silencioso en caso de que el backend aún no responda en la carga inicial
    }
  }

  void navegar(int index) {
    setState(() {
      if (index == 1) {
        _inventarioFiltro = FiltroVigencia.vigentes;
      }
      selectedIndex = index;
    });
    if (index == 0 || index == 1) {
      _cargarAlertas();
    }
  }

  void _irAInventarioCaducadas() {
    setState(() {
      _inventarioFiltro = FiltroVigencia.caducadas;
      selectedIndex = 1;
    });
    _cargarAlertas();
  }

  Widget _badgeResumenHeader({
    required IconData icon,
    required String label,
    required int count,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumenInventarioHeader() {
    final alertas = _alertas;
    if (selectedIndex != 1 || alertas == null) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _badgeResumenHeader(
          icon: Icons.warning_amber_rounded,
          label: 'Caducadas',
          count: alertas.vencidas,
          bgColor: const Color(0xFFFEE2E2),
          borderColor: const Color(0xFFFCA5A5),
          textColor: const Color(0xFF991B1B),
        ),
        _badgeResumenHeader(
          icon: Icons.today_outlined,
          label: 'Vencen hoy',
          count: alertas.vencenHoy,
          bgColor: const Color(0xFFFEF3C7),
          borderColor: const Color(0xFFFCD34D),
          textColor: const Color(0xFF92400E),
        ),
        _badgeResumenHeader(
          icon: Icons.schedule_outlined,
          label: 'Por vencer (≤3 días)',
          count: alertas.porVencer,
          bgColor: const Color(0xFFFFEDD5),
          borderColor: const Color(0xFFFDBA74),
          textColor: const Color(0xFF9A3412),
        ),
      ],
    );
  }

  Widget _alertaFlotante() {
    final alertas = _alertas;
    if (selectedIndex != 0 || _alertaCerrada || alertas == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 24,
      bottom: 24,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: alertas.vencidas > 0
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      size: 20,
                      color: alertas.vencidas > 0
                          ? const Color(0xFFB71C1C)
                          : Colors.amber.shade800,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Alertas de vencimiento',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar alerta',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() {
                          _alertaCerrada = true;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Indicador únicamente informativo (deshabilitado para navegación)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.today_outlined, size: 18),
                    label: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Vencen hoy: ${alertas.vencenHoy} '
                        '${alertas.vencenHoy == 1 ? 'unidad' : 'unidades'}',
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      disabledForegroundColor: Colors.amber.shade900,
                      backgroundColor: const Color(0xFFFFFBEB),
                      side: const BorderSide(color: Color(0xFFFCD34D)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Botón interactivo que navega directamente a Inventario -> Caducadas
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _irAInventarioCaducadas,
                    icon: const Icon(Icons.warning_amber_rounded, size: 18),
                    label: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Ya vencidas: ${alertas.vencidas} '
                            '${alertas.vencidas == 1 ? 'unidad' : 'unidades'}',
                          ),
                        ),
                        const Text(
                          'Ver',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB71C1C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: selectedIndex,
            onSelect: navegar,
          ),
          Expanded(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 18,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                      ),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            titulos[selectedIndex],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          _resumenInventarioHeader(),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(30),
                        child: _contenidoActual(),
                      ),
                    ),
                  ],
                ),
                _alertaFlotante(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contenidoActual() {
    if (selectedIndex == 1) {
      return InventarioScreen(
        initialFiltro: _inventarioFiltro,
        onInventarioChanged: _cargarAlertas,
      );
    }

    if (selectedIndex == 2) {
      return const IngresarUnidadScreen();
    }

    if (selectedIndex == 3) {
      return const SolicitudesScreen();
    }

    if (selectedIndex == 4) {
      return const PlanningScreen();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bienvenido al Banco de Sangre',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Seleccione una opción para gestionar '
          'las unidades y solicitudes de sangre.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 30),
        const Text(
          'Opciones disponibles',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 15),
        _opcion('Consultar inventario', 1),
        _opcion('Registrar unidad de sangre', 2),
        _opcion('Ver solicitudes de sangre', 3),
        _opcion('Gestionar citas de extracción', 4), // NUEVO acceso rápido
      ],
    );
  }

  Widget _opcion(String texto, int destino) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: 400,
        child: OutlinedButton(
          onPressed: () => navegar(destino),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.all(18),
            side: const BorderSide(
              color: Color(0xFFE5E7EB),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(texto),
        ),
      ),
    );
  }
}
