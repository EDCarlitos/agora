import 'package:flutter_test/flutter_test.dart';
import 'package:agora/main.dart';

void main() {
  testWidgets('Login page renders correctly smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that login title and input fields are rendered.
    expect(find.text('Ágora'), findsOneWidget);
    expect(find.text('Portal Institucional'), findsOneWidget);
    expect(find.text('Correo Institucional'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });
}
