import 'dart:async';
import 'package:ezo_core_models/ezo_core_models.dart';
import 'vernacular_strings.dart';

class LocaleController {
  static final LocaleController _instance = LocaleController._internal();
  factory LocaleController() => _instance;
  LocaleController._internal();

  RegionalLanguage _currentLanguage = RegionalLanguage.en;
  final StreamController<RegionalLanguage> _controller = StreamController<RegionalLanguage>.broadcast();

  RegionalLanguage get currentLanguage => _currentLanguage;
  Stream<RegionalLanguage> get onLanguageChanged => _controller.stream;

  void setLanguage(RegionalLanguage language) {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      _controller.add(language);
    }
  }

  /// 1-tap translation helper
  String tr(String key) {
    return VernacularStrings.get(key, language: _currentLanguage);
  }

  String getLanguageDisplayName(RegionalLanguage lang) {
    return VernacularStrings.languageNames[lang.name] ?? lang.name.toUpperCase();
  }

  List<RegionalLanguage> get supportedLanguages => RegionalLanguage.values;
}
