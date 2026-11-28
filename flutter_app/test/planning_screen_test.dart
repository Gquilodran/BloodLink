import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blood_link/screens/planning_screen.dart';

Widget _app() => const MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(30),
          child: PlanningScreen(),
        ),
      ),
    );

String _tituloEsperado(DateTime inicio) {
  final fin = sumarDias(inicio, 6);
  return 'Semana del ${formatoFecha(inicio)} al ${formatoFecha(fin)}/${fin.year}';
}

void main() {
  testWidgets('al ingresar muestra la semana actual', (tester) async {
    await tester.pumpWidget(_app());

    final lunes = lunesDe(DateTime.now());

    expect(find.text(_tituloEsperado(lunes)), findsOneWidget);
    expect(find.text('Lunes'), findsOneWidget);
    expect(find.text(formatoFecha(lunes)), findsOneWidget);
    expect(find.text('Domingo'), findsOneWidget);
    expect(find.text(formatoFecha(sumarDias(lunes, 6))), findsOneWidget);
  });

  testWidgets('avanzar y retroceder cambia la semana y los días',
      (tester) async {
    await tester.pumpWidget(_app());

    final lunes = lunesDe(DateTime.now());
    final siguiente = sumarDias(lunes, 7);
    final anterior = sumarDias(lunes, -7);

    await tester.tap(find.byTooltip('Semana siguiente'));
    await tester.pump();

    expect(find.text(_tituloEsperado(siguiente)), findsOneWidget);
    expect(find.text(_tituloEsperado(lunes)), findsNothing);
    expect(find.text(formatoFecha(siguiente)), findsOneWidget);
    expect(find.text(formatoFecha(lunes)), findsNothing);

    await tester.tap(find.byTooltip('Semana anterior'));
    await tester.pump();
    await tester.tap(find.byTooltip('Semana anterior'));
    await tester.pump();

    expect(find.text(_tituloEsperado(anterior)), findsOneWidget);
    expect(find.text(formatoFecha(anterior)), findsOneWidget);

    await tester.tap(find.text('Hoy'));
    await tester.pump();

    expect(find.text(_tituloEsperado(lunes)), findsOneWidget);
  });
}