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
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: ChangeNotifierProvider(
        create: (context) => ChatProvider()..init(),
        child: ChatScreen(),
      ),
    );
  }
}
