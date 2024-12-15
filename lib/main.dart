import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:simple_todo/pages/chat_screen.dart';
import 'package:simple_todo/utils/gigachat_api.dart';
import 'package:simple_todo/utils/token_storage.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox<String>('authBox');
  await Hive.openBox('chatHistory');

  final tokenStorage = TokenStorage();

  final api = GigachatApi();
  final token = await api.getAccessToken();

  if (token != null) {
    await tokenStorage.saveAccessToken(token);
    print('Сохраненный токен: ${tokenStorage.getAccessToken()}');
  } else {
    print('Не удалось получить токен');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Твой карманный чат-бот',
      theme: ThemeData(
        primaryColor: const Color(0xFF4C9BEB),
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF2F2F2),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Color(0xFF4C9BEB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Color(0xFF4A90E2)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          color: Color(0xFF4C9BEB),
          elevation: 4.0,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Color(0xFF4A4A4A)),
        ),
      ),
      home: const ChatScreen(),
    );
  }
}
