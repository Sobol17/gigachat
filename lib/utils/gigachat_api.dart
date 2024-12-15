import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class GigachatApi {
  final Dio _dio = Dio();
  final Box<String> _authBox = Hive.box<String>('authBox');

  GigachatApi() {
    (_dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (client) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  Future<String?> sendMessage(String userMessage) async {
    final String? accessToken = _authBox.get('accessToken');

    if (accessToken == null) {
      return 'Ошибка: Access Token отсутствует.';
    }

    final response = await _dio.post(
      'https://gigachat.devices.sberbank.ru/api/v1/chat/completions',
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ),
      data: {
        "model": "GigaChat",
        "messages": [
          {
            "role": "system",
            "content": "Ты умный ассистент. Отвечай на вопросы пользователей естественно и дружелюбно."
          },
          {
            "role": "user",
            "content": userMessage,
          }
        ],
        "stream": false,
        "update_interval": 0
      },
    );

    if (response.statusCode == 200) {
      return response.data['choices'][0]['message']['content'];
    } else {
      return 'Ошибка: ${response.statusCode} - ${response.data}';
    }
  }

  Future<String?> getAccessToken() async {
    const url = 'https://ngw.devices.sberbank.ru:9443/api/v2/oauth';
    const authorizationKey = 'MjIyYjc3NDktY2Q1MS00ZTQzLWI1ZmMtYzk3ODVmYTljNzZhOjk1NTExODJlLWVjMjctNDkzYS1iN2Y0LTFhZmM5MzI0ODFlZA==';

    final rqUID = const Uuid().v4();

    final response = await _dio.post(
      url,
      options: Options(
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'RqUID': rqUID,
          'Authorization': 'Basic $authorizationKey',
          'verify_ssl_certs': false
        },
      ),
      data: {
        'scope': 'GIGACHAT_API_PERS',
      },
    );

    if (response.statusCode == 200) {
      final accessToken = response.data['access_token'];
      return accessToken;
    } else {
      print('Ошибка при получении токена: ${response.statusCode}');
      return null;
    }
  }
}
