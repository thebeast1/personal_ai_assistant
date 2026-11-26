import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_ai_assistant/core/network/error/failure.dart';
import 'package:personal_ai_assistant/core/tools/tool_result.dart';
import 'package:personal_ai_assistant/core/use_cases/use_cases.dart';
import 'package:personal_ai_assistant/features/weather/data/models/weather_model.dart';
import 'package:personal_ai_assistant/features/weather/domain/enums/weather_condition.dart';
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

  test('the definition takes no arguments', () {
    expect(tool.name, 'get_local_weather');
    expect(tool.definition.parameters['required'], isEmpty);
  });

  test('success returns the weather map', () async {
    when(() => useCase(any())).thenAnswer((_) async => const Right(weather));

    final result = await tool.execute({}) as ToolSuccess;

    expect(result.data, weather.toJson());
  });

  test('no location tells Gemma to ask for the city', () async {
    when(
      () => useCase(any()),
    ).thenAnswer((_) async => Left(LocationFailure()));

    final result = await tool.execute({}) as ToolFailure;

    expect(result.code, 'location_unavailable');
    expect(result.message, contains('Ask the user'));
    expect(result.message, contains('get_weather'));
  });

  test('other failures keep the get_weather codes', () async {
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
    when(() => useCase(any())).thenAnswer((_) async => const Right(weather));

    await tool.execute({'city': 'ignored'});

    verify(() => useCase(any())).called(1);
  });
}
