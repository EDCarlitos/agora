import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agora/main.dart';

void main() {
  testWidgets('Login page renders correctly smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that login title and input fields are rendered.
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('Correo Institucional'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);

    // Verify development quick login helper section exists.
    expect(find.text('Accesos Rápidos (Modo Desarrollo)'), findsOneWidget);
    expect(find.text('Estudiante'), findsOneWidget);
  });
}
