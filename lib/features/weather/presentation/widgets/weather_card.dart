import 'package:material_ui/material_ui.dart';

import '../../../../core/localization/app_strings.dart';
import '../../data/models/weather_model.dart';
import '../../domain/enums/weather_condition.dart';

/// The current weather, shown in the chat above Gemma's reply.
/// [data] is the `get_weather` tool's result ([WeatherModel.toJson]).
class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final weather = WeatherModel.fromJson(data);
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final place = [
      weather.city,
      weather.country,
    ].where((s) => s.isNotEmpty).join(strings.isArabic ? '، ' : ', ');

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Row(
                spacing: 12,
                children: [
                  Icon(
                    _icon(weather.condition),
                    size: 44,
                    color: colors.primary,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place,
                          style: text.titleSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          strings.weatherCondition(weather.condition.name),
                          style: text.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _degrees(weather.temperatureC),
                    style: text.displaySmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _Stat(
                    icon: Icons.thermostat_rounded,
                    label:
                        '${strings.feelsLike} ${_degrees(weather.feelsLikeC)}',
                  ),
                  _Stat(
                    icon: Icons.water_drop_outlined,
                    label: '${strings.humidity} ${weather.humidity}%',
                  ),
                  _Stat(
                    icon: Icons.air_rounded,
                    label:
                        '${strings.wind} ${weather.windKmh.round()} ${strings.kmPerHour}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _degrees(double celsius) => '${celsius.round()}°';

  static IconData _icon(WeatherCondition condition) => switch (condition) {
    WeatherCondition.clear => Icons.wb_sunny_rounded,
    WeatherCondition.partlyCloudy => Icons.cloud_queue_rounded,
    WeatherCondition.cloudy => Icons.cloud_rounded,
    WeatherCondition.fog => Icons.foggy,
    WeatherCondition.drizzle => Icons.grain_rounded,
    WeatherCondition.rain => Icons.umbrella_rounded,
    WeatherCondition.snow => Icons.ac_unit_rounded,
    WeatherCondition.thunderstorm => Icons.thunderstorm_rounded,
    WeatherCondition.unknown => Icons.help_outline_rounded,
  };
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Icon(icon, size: 16, color: colors.onSurfaceVariant),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
