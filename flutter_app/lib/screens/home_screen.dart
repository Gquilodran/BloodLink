import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import 'inventario_screen.dart';
import 'ingresar_unidad_screen.dart';
import 'solicitudes_screen.dart';
import 'citas_screen.dart'; // NUEVO: pantalla de citas

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  // NUEVO: se añade el título para el índice 4
  final titulos = [
    'Inicio',
    'Inventario de sangre',
    'Ingresar unidad de sangre',
    'Solicitudes de sangre',
    'Citas de extracción', // <-- nueva opción
  ];

  void navegar(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Sidebar(
            selectedIndex: selectedIndex,
            onSelect: navegar,
            // NOTA: deberás añadir la opción 'Citas' dentro de Sidebar
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                  child: Text(
                    titulos[selectedIndex],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
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
          ),
        ],
      ),
    );
  }

  Widget _contenidoActual() {
    if (selectedIndex == 1) {
      return InventarioScreen();
    }

    if (selectedIndex == 2) {
      return const IngresarUnidadScreen();
    }

    if (selectedIndex == 3) {
      return const SolicitudesScreen();
    }

    // NUEVO: ruta para la pantalla de citas
    if (selectedIndex == 4) {
      return const CitasScreen();
    }

    // Contenido por defecto (Inicio)
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