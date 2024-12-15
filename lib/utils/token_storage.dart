import 'package:hive/hive.dart';

class TokenStorage {
  final Box<String> _authBox = Hive.box<String>('authBox');

  Future<void> saveAccessToken(String token) async {
    await _authBox.put('accessToken', token);
    print('Токен сохранен: $token');
  }

  String? getAccessToken() {
    return _authBox.get('accessToken');
  }

  Future<void> deleteAccessToken() async {
    await _authBox.delete('accessToken');
    print('Токен удален');
  }
}
