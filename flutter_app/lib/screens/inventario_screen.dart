
import 'package:flutter/material.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() =>
      _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  String filtroTipo = 'Todos';

  // La lista se llenará desde el backend posteriormente.
  final List<Map<String, String>> unidades = [];

  @override
  Widget build(BuildContext context) {
    final filtradas = unidades.where((unidad) {
      return filtroTipo == 'Todos' ||
          unidad['tipo'] == filtroTipo;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Inventario de sangre',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Consulte las unidades de sangre registradas.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 25),

        SizedBox(
          width: 200,
          child: DropdownButtonFormField<String>(
            initialValue: filtroTipo,
            decoration: const InputDecoration(
              labelText: 'Tipo de sangre',
              border: OutlineInputBorder(),
            ),
            items: [
              'Todos', 'A+', 'A-', 'B+', 'B-',
              'AB+', 'AB-', 'O+', 'O-',
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

        const SizedBox(height: 25),

        SizedBox(
          width: double.infinity,
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: const BorderSide(
                color: Color(0xFFE5E7EB),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Tipo')),
                  DataColumn(label: Text('Ubicación')),
                  DataColumn(label: Text('Extracción')),
                  DataColumn(label: Text('Caducidad')),
                ],
                rows: filtradas.map((unidad) {
                  return DataRow(
                    cells: [
                      DataCell(Text(unidad['id'] ?? '')),
                      DataCell(Text(unidad['tipo'] ?? '')),
                      DataCell(Text(unidad['ubicacion'] ?? '')),
                      DataCell(Text(unidad['extraccion'] ?? '')),
                      DataCell(Text(unidad['caducidad'] ?? '')),
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
              'No hay unidades cargadas. '
              'Pendiente de conexión con el backend.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
      ],
    );
  }
}
