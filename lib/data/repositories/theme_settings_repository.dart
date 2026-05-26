import 'package:hive/hive.dart';
import 'package:todolist/data/hive/box_names.dart';

class ThemeSettingsRepository {
  ThemeSettingsRepository({Box<dynamic>? box})
    : _box = box ?? Hive.box<dynamic>(BoxNames.settings);

  static const String themeKey = 'theme_key';
  static const String bodyFontKey = 'body_font_key';

  final Box<dynamic> _box;

  String? getThemeKey() {
    return _box.get(themeKey) as String?;
  }

  Future<void> setThemeKey(String key) {
    return _box.put(themeKey, key);
  }

  String? getBodyFontKey() {
    return _box.get(bodyFontKey) as String?;
  }

  Future<void> setBodyFontKey(String key) {
    return _box.put(bodyFontKey, key);
  }
}
