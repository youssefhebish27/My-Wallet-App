import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/login_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // (للتخزين المؤقت Hive تشغيل)
  await Hive.initFlutter();
  await Hive.openBox('expense_database');

  // (نسخ البيانات من صورتك ووضعها هنا) -> تم استبدالها بالطريقة الآمنة 👇
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
      ),
      home: const LoginScreen(),
    );
  }
}
