import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefKeys {
  SharedPrefKeys._();
  static const String apiKey = 'apiKey';
}

enum SettingName {
  apiKey,
}

class Setting {
  final SettingName name;
  String? stringValue;

  Setting(
    this.name, {
    this.stringValue,
  });
}

class SettingsRepository {
  final _settingsController = ReplaySubject<Setting>();

  SettingsRepository() {
    _apiKey.then((value) => addToStream(Setting(SettingName.apiKey, stringValue: value)));
  }

  Stream<Setting> get settingsStream => _settingsController.asBroadcastStream();
  void addToStream(Setting setting) => _settingsController.add(setting);

  Future<void> setApiKey(String apiKey) async {
    (await SharedPreferences.getInstance()).setString(SharedPrefKeys.apiKey, apiKey);
    addToStream(Setting(SettingName.apiKey, stringValue: apiKey));
  }

  Future<String> get _apiKey async {
    final apiKey = (await SharedPreferences.getInstance()).getString(SharedPrefKeys.apiKey);
    if (apiKey == null) return '';
    return apiKey;
  }
}
