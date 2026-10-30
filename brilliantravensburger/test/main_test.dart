import 'package:flutter_test/flutter_test.dart';

import 'package:brilliantravensburger/main.dart' as app;

void main() {
  testWidgets('main opens the sign-in screen', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('INGRESAR'), findsOneWidget);
  });

  testWidgets('authentication screen switches to registration mode', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.text('¿No tienes cuenta? Regístrate'));
    await tester.pumpAndSettle();

    expect(find.text('Crear Cuenta'), findsOneWidget);
    expect(find.text('REGISTRARSE'), findsOneWidget);
  });
}
