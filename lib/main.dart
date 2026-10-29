import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const StudyCardsApp());
}

class StudyCardsApp extends StatelessWidget {
  const StudyCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyCards',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}