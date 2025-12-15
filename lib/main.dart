import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تشغيل Hive (للتخزين المؤقت)
  await Hive.initFlutter();
  await Hive.openBox('expense_database');

  // تشغيل Firebase (انسخ البيانات من صورتك وضعها هنا)
  await Firebase.initializeApp(
    options: const FirebaseOptions(
    apiKey: "AIzaSyARseedabLgUU9VsBri09Kol1qP5eT2XXs",
    authDomain: "my-wallet-app-2c2bc.firebaseapp.com",
    projectId: "my-wallet-app-2c2bc",
    storageBucket: "my-wallet-app-2c2bc.firebasestorage.app",
    messagingSenderId: "1035533510982",
    appId: "1:1035533510982:web:1ac7d3e58eb7e53f5c1d47",
    measurementId: "G-S2FWYV3YYK"
    ),
  );

  runApp(const ExpenseApp());
}

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Wallet',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}