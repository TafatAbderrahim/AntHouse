import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/admin_shell.dart';
import 'screens/employee_shell.dart';
import 'screens/sup_shell.dart';

void main() {
  runApp(const BMSWarehouseApp());
}

class BMSWarehouseApp extends StatelessWidget {
  const BMSWarehouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ANT BMS — WMS Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF006D84),
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF6F6F6),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 72, fontWeight: FontWeight.w800),
          displayMedium: TextStyle(fontSize: 56, fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
          labelLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const LoginScreen(),
        '/login': (_) => const LoginScreen(),
        '/admin': (_) => const AdminShell(),
        '/employee': (_) => const EmployeeShell(),
        '/supervisor': (_) => const SupervisorShellNew(),
      },
    );
  }
}
