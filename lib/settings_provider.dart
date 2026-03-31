import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // 🔹 Core Settings
  String serverUrl = ''; // Dynamic Ngrok/Cloudflare URL
  bool isDarkMode = true;
  bool saveLog = true;
  bool notificationsEnabled = true;
  bool autoSaveMedia = false;

  // 🔹 Advanced Settings
  double checkIntervalSeconds = 5.0;
  String storageLocation = '/storage/emulated/0/Download/SecurityNexus';
  String alarmRingtone = 'Default Siren';

  // 🔹 Initialization Status
  bool get isInitialized => _isInitialized;

  SettingsProvider() {
    _loadSettings();
  }

  // 🔹 Load Settings
  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    serverUrl = _prefs.getString('serverUrl') ?? '';
    isDarkMode = _prefs.getBool('isDarkMode') ?? true;
    saveLog = _prefs.getBool('saveLog') ?? true;
    notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? true;
    autoSaveMedia = _prefs.getBool('autoSaveMedia') ?? false;
    checkIntervalSeconds = _prefs.getDouble('checkInterval') ?? 5.0;

    storageLocation = _prefs.getString('storageLocation') ??
        '/storage/emulated/0/Download/SecurityNexus';

    alarmRingtone =
        _prefs.getString('alarmRingtone') ?? 'Default Siren';

    _isInitialized = true;
    notifyListeners();
  }

  // 🔹 Update Server URL
  void updateServerUrl(String url) {
    serverUrl = url;
    _prefs.setString('serverUrl', url);
    notifyListeners();
  }

  // 🔹 Theme Toggle
  void updateTheme(bool value) {
    isDarkMode = value;
    _prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  // 🔹 Notifications Toggle
  void toggleNotifications(bool value) {
    notificationsEnabled = value;
    _prefs.setBool('notificationsEnabled', value);
    notifyListeners();
  }

  // 🔹 Save Log Toggle
  void toggleSaveLog(bool value) {
    saveLog = value;
    _prefs.setBool('saveLog', value);
    notifyListeners();
  }

  // 🔹 Auto Save Media Toggle
  void toggleAutoSave(bool value) {
    autoSaveMedia = value;
    _prefs.setBool('autoSaveMedia', value);
    notifyListeners();
  }

  // 🔹 Update Interval (Slider)
  void updateInterval(double value) {
    checkIntervalSeconds = value;
    _prefs.setDouble('checkInterval', value);
    notifyListeners();
  }

  // 🔹 Update Storage Location
  void updateStorageLocation(String path) {
    storageLocation = path;
    _prefs.setString('storageLocation', path);
    notifyListeners();
  }

  // 🔹 Update Alarm Ringtone
  void updateRingtone(String tone) {
    alarmRingtone = tone;
    _prefs.setString('alarmRingtone', tone);
    notifyListeners();
  }
}