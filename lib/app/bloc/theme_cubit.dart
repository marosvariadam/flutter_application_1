import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const _key = 'theme_mode';
  final FlutterSecureStorage _storage;

  ThemeCubit({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(ThemeMode.light);

  Future<void> load() async {
    final value = await _storage.read(key: _key);
    emit(value == 'dark' ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await _storage.write(key: _key, value: next == ThemeMode.dark ? 'dark' : 'light');
    emit(next);
  }
}
