import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:simple_todo/pages/chat_screen.dart';
import 'package:simple_todo/utils/gigachat_api.dart';
import 'package:simple_todo/utils/theme.dart';
import 'package:simple_todo/utils/token_storage.dart';
import 'package:provider/provider.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox<String>('authBox');
  await Hive.openBox('chatHistory');
  await Hive.openBox('chatsList');
  await Hive.openBox<String>('themeBox');

  final tokenStorage = TokenStorage();

  final api = GigachatApi();
  final token = await api.getAccessToken();

  if (token != null) {
    await tokenStorage.saveAccessToken(token);
    print('Сохраненный токен: ${tokenStorage.getAccessToken()}');
  } else {
    print('Не удалось получить токен');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Твой карманный чат-бот',
          themeMode: themeProvider.themeMode, // Используем текущую тему
          theme: ThemeData(
            // Светлая тема
            primaryColor: const Color(0xFFEAEAEA),
            scaffoldBackgroundColor: Colors.white,
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF2F2F2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
              ),
            ),
            appBarTheme: const AppBarTheme(
              color: Color(0xFFEAEAEA),
              elevation: 4.0,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFF333333)),
              bodyMedium: TextStyle(color: Color(0xFF333333)),
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            // Темная тема
            primaryColor: const Color(0xFF121212),
            scaffoldBackgroundColor: const Color(0xFF1E1E1E),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
              ),
            ),
            appBarTheme: const AppBarTheme(
              color: Color(0xFF121212),
              elevation: 4.0,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFFEAEAEA)),
              bodyMedium: TextStyle(color: Color(0xFFEAEAEA)),
            ),
          ),
          home: ChatScreen(chatId: 'chat_1'),
        );
      },
    );
  }
}
