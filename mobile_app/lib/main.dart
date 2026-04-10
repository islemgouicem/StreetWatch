import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'widgets/navigation_wrapper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StreetWatch',
      theme: AppTheme.lightTheme,
      home: const NavigationWrapper(),
    );
  }
}
