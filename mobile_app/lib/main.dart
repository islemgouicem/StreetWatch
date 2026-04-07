import 'package:flutter/material.dart';
import 'package:mobile_app/features/Map/presentation/page/map.dart';
import 'package:mobile_app/features/Ranks/presentation/page/ranks.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: RanksPage(),
    );
  }
}

