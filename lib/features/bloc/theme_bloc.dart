import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// EVENTS
abstract class ThemeEvent {}
class ToggleThemeEvent extends ThemeEvent {}

// BLOC
class ThemeBloc extends Bloc<ThemeEvent, ThemeMode> {
  ThemeBloc() : super(ThemeMode.dark) {
    on<ToggleThemeEvent>((event, emit) {
      if (state == ThemeMode.dark) {
        emit(ThemeMode.light);
      } else {
        emit(ThemeMode.dark);
      }
    });
  }
}
