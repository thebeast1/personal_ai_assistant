import 'package:flutter_edge_ai/engine.dart';
import 'package:flutter_edge_ai_litertlm/flutter_edge_ai_litertlm.dart';
import 'package:material_ui/material_ui.dart';
import 'package:personal_ai_assistant/core/localization/app_strings.dart';
import 'package:personal_ai_assistant/core/services/injection.dart';
import 'package:personal_ai_assistant/features/app_settings/presentation/provider/app_settings_provider.dart';
import 'package:personal_ai_assistant/features/chat/presentation/chat_screen.dart';
import 'package:personal_ai_assistant/features/chat/presentation/provider/chat_provider.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterEdgeAi.initialize(inferenceEngines: [LiteRtLmEngine()]);
  await configureInjection();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppSettingsProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Task-switcher title, in the app's language.
      onGenerateTitle: (context) => AppStrings.of(context).assistantName,
      // Arabic switches the whole app to right-to-left.
      locale: settings.locale,
      supportedLocales: AppSettingsProvider.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Light and dark themes from the same seed. Follows the phone unless the
      // user picked light or dark (through Khadeja's change_theme tool).
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: settings.themeMode,
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
