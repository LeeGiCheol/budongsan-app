import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:budongsan_app/app/app.dart';
import 'package:budongsan_app/features/saved_calculations/providers/saved_calculation_provider.dart';
import 'package:budongsan_app/features/settings/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final savedCalcProvider = SavedCalculationProvider();
  await savedCalcProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: savedCalcProvider),
      ],
      child: const BudongsanApp(),
    ),
  );
}
