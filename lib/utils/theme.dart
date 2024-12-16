import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider with ChangeNotifier {
  final Box<String> _themeBox = Hive.box<String>('themeBox');

  ThemeProvider() {
    // Загрузка темы из Hive при инициализации
    final savedTheme = _themeBox.get('themeMode', defaultValue: 'light');
    _themeMode = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  late ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _themeBox.put('themeMode', _themeMode == ThemeMode.light ? 'light' : 'dark'); // Сохранение темы в Hive
    notifyListeners(); // Уведомляем слушателей об изменении
  }
}