import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'presentation/main_layout.dart';

import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(
    const ProviderScope(
      child: PelitaApp(),
    ),
  );
}

class PelitaApp extends ConsumerWidget {
  const PelitaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'PELITA',
      debugShowCheckedModeBanner: false,
      theme: themeAsync.value ?? AppTheme.darkTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Primary
        Locale('en', 'US'), // Secondary
      ],
      locale: const Locale('id', 'ID'),
      home: const MainLayout(),
    );
  }
}
