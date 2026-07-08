import 'package:flutter_test/flutter_test.dart';

import 'package:samagardiennage/main.dart';

void main() {
  testWidgets('Login screen displays admin and QR access', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SamaGardiennageApp());

    expect(find.text('Sama Gardiennage'), findsOneWidget);
    expect(find.text('CONNEXION ADMINISTRATEUR'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Scanner mon QR Code'), findsOneWidget);
  });
}
