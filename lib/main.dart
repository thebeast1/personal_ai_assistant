import 'package:flutter_edge_ai/engine.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';
import 'package:material_ui/material_ui.dart';
import 'package:personal_ai_assistant/core/localization/app_strings.dart';
import 'package:personal_ai_assistant/core/localization/locale_provider.dart';
import 'package:personal_ai_assistant/features/chat/presentation/chat_screen.dart';
import 'package:personal_ai_assistant/features/chat/presentation/provider/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterEdgeAi.initialize(inferenceEngines: [LiteRtLmEngine()]);

  // Loaded before runApp so the first frame already uses the saved language.
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: {LocaleProvider.prefsKey},
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(prefs),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Task-switcher title, in the app's language.
      onGenerateTitle: (context) => AppStrings.of(context).assistantName,
      // Arabic switches the whole app to right-to-left.
      locale: context.watch<LocaleProvider>().locale,
      supportedLocales: LocaleProvider.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Light and dark themes from the same seed; follows the phone's setting.
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: ChangeNotifierProvider(
        create: (context) => ChatProvider()..init(),
        child: ChatScreen(),
      ),
    );
  }
}

ThemeData _theme(Brightness brightness) => ThemeData(
  colorScheme: .fromSeed(seedColor: Colors.deepPurple, brightness: brightness),
);