import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:samagardiennage/main.dart';
import 'package:samagardiennage/models/app_user.dart';
import 'package:samagardiennage/views/collector_dashboard_view.dart';
import 'package:samagardiennage/views/habitants_view.dart';

void main() {
  testWidgets('Login screen displays admin and QR access', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SamaGardiennageApp());

    expect(find.text('Sama Gardiennage'), findsOneWidget);
    expect(find.text('CONNEXION UTILISATEUR'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Scanner mon QR Code'), findsOneWidget);
  });

  testWidgets('Collector dashboard opens the habitants page', (
    WidgetTester tester,
  ) async {
    final user = AppUser(
      id: 'collector-test',
      fullName: 'Moussa Camara',
      email: 'moussa@test.sn',
      type: AppUserType.collecteur,
      isActive: true,
      address: 'Juste 208',
      quartierName: 'Quartier Medina',
    );

    await tester.pumpWidget(
      MaterialApp(home: CollectorDashboardView(user: user)),
    );

    expect(find.byType(HabitantsView), findsNothing);

    await tester.tap(find.text('Habitants').first);
    await tester.pumpAndSettle();

    expect(find.byType(HabitantsView), findsOneWidget);
  });

  testWidgets('Habitants page returns to the collector dashboard', (
    WidgetTester tester,
  ) async {
    final user = AppUser(
      id: 'collector-test',
      fullName: 'Moussa Camara',
      email: 'moussa@test.sn',
      type: AppUserType.collecteur,
      isActive: true,
      address: 'Juste 208',
      quartierName: 'Quartier Medina',
    );

    await tester.pumpWidget(
      MaterialApp(home: CollectorDashboardView(user: user)),
    );

    await tester.tap(find.text('Habitants').first);
    await tester.pumpAndSettle();

    expect(find.byType(HabitantsView), findsOneWidget);

    await tester.tap(find.text('Accueil').first);
    await tester.pumpAndSettle();

    expect(find.byType(CollectorDashboardView), findsOneWidget);
    expect(find.byType(HabitantsView), findsNothing);
  });
}
