
import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final opciones = [
      ('Inicio', Icons.home_outlined),
      ('Inventario', Icons.inventory_2_outlined),
      ('Ingresar unidad', Icons.add_circle_outline),
      ('Solicitudes', Icons.assignment_outlined),
      ('Planning  semanal', Icons.calendar_month_outlined),
    ];

    return Container(
      width: 220,
      color: const Color(0xFFF3F4F6),
      child: Column(
        children: [
          const SizedBox(height: 25),
          const Icon(
            Icons.bloodtype_outlined,
            color: Color(0xFFB71C1C),
            size: 35,
          ),
          const SizedBox(height: 8),
          const Text(
            'BloodLink',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          for (int i = 0; i < opciones.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 3,
              ),
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                selected: selectedIndex == i,
                selectedTileColor: const Color(0xFFE5E7EB),
                leading: Icon(
                  opciones[i].$2,
                  size: 21,
                  color: selectedIndex == i
                      ? const Color(0xFFB71C1C)
                      : Colors.black54,
                ),
                title: Text(
                  opciones[i].$1,
                  style: const TextStyle(fontSize: 14),
                ),
                onTap: () => onSelect(i),
              ),
            ),
        ],
      ),
    );
  }
}
