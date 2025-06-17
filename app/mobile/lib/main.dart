import 'package:flutter/material.dart';
import 'package:mobile/services/cache/cache_scheduler.dart';
import 'styles/theme.dart';
import 'views/splash_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = 'pk_test_51RPoLaDA0YiX3e5zdwlX5j0VVCDtdCRqm6AqIqiTlHPkIRXOQIqnIqYWMfXa52KPcKKN82K8V2y3oJerkYGFS9hJ00l4DkazC0';
  await initializeDateFormatting('pl', null);
  CacheScheduler.start();
  runApp(const PetifyApp());
}

class PetifyApp extends StatelessWidget {
  const PetifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('pl', ''),
      ],
      locale: const Locale('pl', 'PL'),
      home: const SplashScreen(),
    );
  }
}
