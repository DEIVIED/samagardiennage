import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'views/login_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? firebaseError;
  try {
    await Firebase.initializeApp();
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
    );
  } catch (error) {
    firebaseError = error;
  }

  runApp(SamaGardiennageApp(firebaseError: firebaseError));
}

class SamaGardiennageApp extends StatelessWidget {
  const SamaGardiennageApp({super.key, this.firebaseError});

  final Object? firebaseError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sama Gardiennage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF172747),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      home: LoginView(firebaseError: firebaseError),
    );
  }
}
