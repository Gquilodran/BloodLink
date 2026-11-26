import 'package:flutter_test/flutter_test.dart';
import 'package:blood_link/main.dart';

void main() {
  testWidgets('BloodLink smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BloodLinkApp());

    expect(find.text('BloodLink'), findsOneWidget);
    expect(find.text('Bienvenido al Banco de Sangre'), findsOneWidget);
  });
}
