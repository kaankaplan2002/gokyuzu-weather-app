import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const GokyuzuApp());
}

class GokyuzuApp extends StatelessWidget {
  const GokyuzuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GökYüzü - Premium Hava Durumu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0915),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF6366F1),
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFFA855F7),
          tertiary: const Color(0xFF06B6D4),
          surface: const Color(0xFF16152B),
        ),
        fontFamily: 'Outfit',
        cardTheme: CardThemeData(
          color: const Color(0x0CFFFFFF),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0x1AFFFFFF), width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0x05FFFFFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0x0DFFFFFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0x0DFFFFFF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
          ),
          hintStyle: const TextStyle(color: Color(0x80FFFFFF)),
          prefixIconColor: const Color(0x80FFFFFF),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
