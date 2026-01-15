import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:iteagrow/core/design_system/design_system.dart';
import 'package:iteagrow/core/routing/premium_router.dart';
import 'package:iteagrow/l10n/app_localizations.dart';
import 'package:iteagrow/core/providers/locale_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: TeaColors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: ITeaGrowApp(),
    ),
  );
}

/// Theme mode provider for switching between light and dark themes
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

/// Locale provider for language switching (moved to locale_provider.dart for persistence)
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

class ITeaGrowApp extends ConsumerWidget {
  const ITeaGrowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(premiumRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(persistentLocaleProvider);

    return MaterialApp.router(
      title: 'iTeaGrow',
      debugShowCheckedModeBanner: false,

      // Premium Tea Theme
      theme: TeaTheme.light,
      darkTheme: TeaTheme.dark,
      themeMode: themeMode,

      // Localization - English, Sinhala, Tamil
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,

      routerConfig: router,

      // Scroll behavior for smooth scrolling
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
    );
  }
}
