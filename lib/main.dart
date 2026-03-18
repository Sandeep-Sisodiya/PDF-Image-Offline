import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'models/history_item.dart';
import 'providers/settings_provider.dart';
import 'providers/history_provider.dart';
import 'screens/shell/main_shell.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/image_to_pdf/image_to_pdf_screen.dart';
import 'screens/pdf_to_image/pdf_to_image_screen.dart';
import 'screens/compress_image/compress_image_screen.dart';
import 'screens/compress_pdf/compress_pdf_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(HistoryItemAdapter());

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.backgroundDarkNavy,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize providers
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  final historyProvider = HistoryProvider();
  await historyProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: historyProvider),
      ],
      child: const DocuMasterApp(),
    ),
  );
}

class DocuMasterApp extends StatelessWidget {
  const DocuMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'PDF Image Offline',
          debugShowCheckedModeBanner: false,
          theme: settings.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
          home: const SplashScreen(nextScreen: MainShell()),
          routes: {
            '/image-to-pdf': (context) => const ImageToPdfScreen(),
            '/pdf-to-image': (context) => const PdfToImageScreen(),
            '/compress-image': (context) => const CompressImageScreen(),
            '/compress-pdf': (context) => const CompressPdfScreen(),
          },
        );
      },
    );
  }
}
