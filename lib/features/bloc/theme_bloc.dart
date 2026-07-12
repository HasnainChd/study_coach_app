import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

// EVENTS
abstract class ThemeEvent {}

class ToggleThemeEvent extends ThemeEvent {}

// BLOC
class ThemeBloc extends Bloc<ThemeEvent, ThemeMode> {
  final Box _box;

  static const String _keyThemeMode = 'themeMode';

  ThemeBloc(this._box) : super(_loadSavedThemeMode(_box)) {
    on<ToggleThemeEvent>(_onToggleTheme);
  }

  static ThemeMode _loadSavedThemeMode(Box box) {
    final saved = box.get(_keyThemeMode);
    if (saved == 'light') return ThemeMode.light;
    return ThemeMode.dark;
  }

  Future<void> _onToggleTheme(
    ToggleThemeEvent event,
    Emitter<ThemeMode> emit,
  ) async {
    final next =
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _box.put(
      _keyThemeMode,
      next == ThemeMode.light ? 'light' : 'dark',
    );
    emit(next);
  }
}
