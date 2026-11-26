import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_ai_assistant/core/network/error/failure.dart';
import 'package:personal_ai_assistant/core/tools/tool_result.dart';
import 'package:personal_ai_assistant/core/use_cases/use_cases.dart';
import 'package:personal_ai_assistant/features/weather/data/models/weather_model.dart';
import 'package:personal_ai_assistant/features/weather/domain/entities/local_weather_result.dart';
import 'package:personal_ai_assistant/features/weather/domain/enums/weather_condition.dart';
import 'package:personal_ai_assistant/features/weather/domain/enums/weather_source.dart';
import 'package:personal_ai_assistant/features/weather/domain/use_cases/get_local_weather_use_case.dart';
import 'package:personal_ai_assistant/features/weather/tool/get_local_weather_tool.dart';

class _MockGetLocalWeather extends Mock implements GetLocalWeatherUseCase {}

void main() {
  const weather = WeatherModel(
    city: 'Giza',
    country: 'Egypt',
    temperatureC: 24,
    feelsLikeC: 25,
    humidity: 40,
    windKmh: 12,
    condition: WeatherCondition.clear,
  );

  late _MockGetLocalWeather useCase;
  late GetLocalWeatherTool tool;

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() {
    useCase = _MockGetLocalWeather();
    tool = GetLocalWeatherTool(getLocalWeatherUseCase: useCase);
  });

  void answer(WeatherSource source) => when(() => useCase(any())).thenAnswer(
    (_) async => Right(LocalWeatherResult(weather: weather, source: source)),
  );

  test('the definition takes no arguments', () {
    expect(tool.name, 'get_local_weather');
    expect(tool.definition.parameters['required'], isEmpty);
  });

  test('current location: the weather map plus its source', () async {
    answer(WeatherSource.currentLocation);

    final result = await tool.execute({}) as ToolSuccess;

    expect(result.data, {...weather.toJson(), 'source': 'current_location'});
  });

  test('default city: says so in the source', () async {
    answer(WeatherSource.defaultCity);

    final result = await tool.execute({}) as ToolSuccess;

    expect(result.data['source'], 'default_city');
    expect(result.data['city'], 'Giza');
  });

  test('failures become the same codes as get_weather', () async {
    final cases = <Failure, String>{
      NetworkFailure(): 'no_internet',
      NotFoundFailure(): 'city_not_found',
      ServerFailure(): 'service_unavailable',
    };
    for (final entry in cases.entries) {
      when(() => useCase(any())).thenAnswer((_) async => Left(entry.key));
      final result = await tool.execute({}) as ToolFailure;
      expect(result.code, entry.value);
    }
  });

  test('extra arguments from the model are ignored', () async {
    answer(WeatherSource.currentLocation);

    await tool.execute({});
    await tool.execute({'city': 'ignored'});

    verify(() => useCase(any())).called(2);
  });
}
