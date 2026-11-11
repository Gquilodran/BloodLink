import 'package:flutter_test/flutter_test.dart';
import 'package:blood_link/main.dart';

void main() {
  testWidgets('BloodLink smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BloodLinkApp());

    // Verify that the upload screen renders the button.
    expect(find.text('Subir archivo'), findsOneWidget);
  });
}
