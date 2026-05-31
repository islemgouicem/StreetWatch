import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/features/auth/presentation/pages/splash_screen.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/offline_sync_service.dart';
import 'package:mobile_app/bloc/index.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught platform error: $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };

  await runZonedGuarded(() async {
    try {
      await Supabase.initialize(
        url: const String.fromEnvironment(
          'SUPABASE_URL',
          defaultValue: 'https://kcqnmcvzngikknstnfle.supabase.co',
        ),
        anonKey: const String.fromEnvironment(
          'SUPABASE_ANON_KEY',
          defaultValue:
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtjcW5tY3Z6bmdpa2tuc3RuZmxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5MTQ0OTgsImV4cCI6MjA5MTQ5MDQ5OH0.UWfh-nPvfyiGPD9aqUvd2DMM0f-K97LrR3JGHLeyqxk',
        ),
      );
    } catch (error, stack) {
      debugPrint('Supabase initialization failed: $error');
      debugPrintStack(stackTrace: stack);
    }

    try {
      await OfflineSyncService().init();
    } catch (error, stack) {
      debugPrint('Offline sync initialization failed: $error');
      debugPrintStack(stackTrace: stack);
    }

    runApp(const MyApp());
  }, (error, stack) {
    debugPrint('Guarded startup error: $error');
    debugPrintStack(stackTrace: stack);
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService(Supabase.instance.client);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => AuthBloc(apiService)),
        BlocProvider<ReportsBloc>(create: (_) => ReportsBloc(apiService)),
        BlocProvider<LeaderboardBloc>(
          create: (_) => LeaderboardBloc(apiService),
        ),
        BlocProvider<UserBloc>(create: (_) => UserBloc(apiService)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'StreetWatch',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
