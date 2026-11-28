import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/text_direction_detector.dart';

class GetWeatherParams {
  GetWeatherParams({required this.city});

  final String city;

  /// Arabic city names are looked up in Arabic, so the answer and the card
  /// show the Arabic name.
  String get language =>
      detectTextDirection(city) == TextDirection.rtl ? 'ar' : 'en';

  /// Query parameters for the geocoding API.
  Map<String, dynamic> toJson() {
    return {'name': city, 'count': 1, 'language': language};
  }
}
