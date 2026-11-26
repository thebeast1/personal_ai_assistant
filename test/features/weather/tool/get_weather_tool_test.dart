import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:personal_ai_assistant/core/network/error/failure.dart';
import 'package:personal_ai_assistant/core/tools/tool_result.dart';
import 'package:personal_ai_assistant/features/weather/data/models/weather_model.dart';
import 'package:personal_ai_assistant/features/weather/domain/enums/weather_condition.dart';
import 'package:personal_ai_assistant/features/weather/domain/params/get_weather_params.dart';
import 'package:personal_ai_assistant/features/weather/domain/use_cases/get_current_weather_use_case.dart';
import 'package:personal_ai_assistant/features/weather/tool/get_weather_tool.dart';

class _MockGetCurrentWeather extends Mock implements GetCurrentWeatherUseCase {}

void main() {
  const weather = WeatherModel(
    city: 'Cairo',
    country: 'Egypt',
    temperatureC: 24,
    feelsLikeC: 25,
    humidity: 40,
    windKmh: 12,
    condition: WeatherCondition.clear,
  );

  late _MockGetCurrentWeather useCase;
  late GetWeatherTool tool;

  setUpAll(() => registerFallbackValue(GetWeatherParams(city: '')));

  setUp(() {
    useCase = _MockGetCurrentWeather();
    tool = GetWeatherTool(getCurrentWeatherUseCase: useCase);
  });

  test('the definition asks Gemma for a required city', () {
    expect(tool.name, 'get_weather');
    expect(tool.definition.parameters['required'], ['city']);
  });

  test('missing, empty or non-text city returns invalid_arguments', () async {
    for (final args in [
      <String, dynamic>{},
      {'city': ''},
      {'city': '   '},
      {'city': 42},
    ]) {
      final result = await tool.execute(args);
      expect((result as ToolFailure).code, 'invalid_arguments', reason: '$args');
    }
    verifyNever(() => useCase(any()));
  });

  test('success trims the city and returns the weather map', () async {
    GetWeatherParams? asked;
    when(() => useCase(any())).thenAnswer((call) async {
      asked = call.positionalArguments.first as GetWeatherParams;
      return const Right(weather);
    });

    final result = await tool.execute({'city': ' Cairo '});

    expect(asked?.city, 'Cairo');
    expect((result as ToolSuccess).data, weather.toJson());
  });

  test('each failure becomes a code Gemma can explain', () async {
    final cases = <Failure, String>{
      NotFoundFailure(): 'city_not_found',
      NetworkFailure(): 'no_internet',
      ServerFailure(): 'service_unavailable',
    };
    for (final entry in cases.entries) {
      when(() => useCase(any())).thenAnswer((_) async => Left(entry.key));
      final result = await tool.execute({'city': 'Cairo'}) as ToolFailure;
      expect(result.code, entry.value);
      expect(result.message, entry.key.message);
    }
  });
}
