import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:personal_ai_assistant/features/weather/presentation/widgets/weather_card.dart';

const _data = {
  'city': 'Cairo',
  'country': 'Egypt',
  'temperature_c': 24.4,
  'feels_like_c': 25.0,
  'humidity': 40,
  'wind_kmh': 12.0,
  'condition': 'clear',
};

Widget _app({Locale locale = const Locale('en'), ThemeData? theme}) =>
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: theme,
      home: const Scaffold(body: WeatherCard(data: _data)),
    );

void main() {
  testWidgets('shows the city, rounded temperature and English labels', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(find.textContaining('Cairo'), findsOneWidget);
    expect(find.text('24°'), findsOneWidget);
    expect(find.textContaining('Feels like'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
  });

  testWidgets('Arabic shows Arabic labels, right to left', (tester) async {
    await tester.pumpWidget(_app(locale: const Locale('ar')));

    expect(find.textContaining('الإحساس'), findsOneWidget);
    expect(find.text('صافٍ'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(WeatherCard))),
      TextDirection.rtl,
    );
  });

  testWidgets('renders in dark mode', (tester) async {
    await tester.pumpWidget(
      _app(theme: ThemeData(brightness: Brightness.dark)),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(WeatherCard), findsOneWidget);
  });
}
