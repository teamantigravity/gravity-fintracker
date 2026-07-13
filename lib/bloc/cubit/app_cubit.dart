import 'package:fintracker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  late String? username;
  late int themeColor;
  late String? currency;
  late AppThemeMode themeMode;
  late bool appLockEnabled;
  late bool isPro;
  late bool privacyMode;
  late bool dailyDigestEnabled;

  static Future<AppState> getState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    int? themeColor = prefs.getInt("themeColor");
    String? username = prefs.getString("username");
    String? currency = prefs.getString("currency");
    String? themeModeStr = prefs.getString("themeMode");
    bool? appLock = prefs.getBool("appLockEnabled");
    bool? isPro = prefs.getBool("isPro");
    bool? privacyMode = prefs.getBool("privacyMode");
    bool? dailyDigest = prefs.getBool("dailyDigestEnabled");

    AppState appState = AppState();
    appState.themeColor = themeColor ?? 0xFF4285F4; // Google Blue
    appState.username = username;
    appState.currency = currency;
    appState.themeMode = _parseThemeMode(themeModeStr);
    appState.appLockEnabled = appLock ?? false;
    appState.isPro = isPro ?? false;
    appState.privacyMode = privacyMode ?? false;
    appState.dailyDigestEnabled = dailyDigest ?? false;

    return appState;
  }

  static AppThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'amoled':
        return AppThemeMode.amoled;
      default:
        return AppThemeMode.system;
    }
  }
}

class AppCubit extends Cubit<AppState> {
  AppCubit(AppState initialState) : super(initialState);

  Future<void> updateUsername(username) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("username", username);
    emit(await AppState.getState());
  }

  Future<void> updateCurrency(currency) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("currency", currency);
    emit(await AppState.getState());
  }

  Future<void> updateThemeColor(int color) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt("themeColor", color);
    emit(await AppState.getState());
  }

  Future<void> updateThemeMode(AppThemeMode mode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("themeMode", mode.name);
    emit(await AppState.getState());
  }

  Future<void> updateAppLock(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("appLockEnabled", enabled);
    emit(await AppState.getState());
  }

  Future<void> updatePro(bool isPro) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("isPro", isPro);
    emit(await AppState.getState());
  }

  Future<void> updatePrivacyMode(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("privacyMode", enabled);
    emit(await AppState.getState());
  }

  Future<void> updateDailyDigest(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("dailyDigestEnabled", enabled);
    emit(await AppState.getState());
  }

  Future<void> reset() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove("currency");
    await prefs.remove("themeColor");
    await prefs.remove("username");
    await prefs.remove("themeMode");
    await prefs.remove("appLockEnabled");
    await prefs.remove("isPro");
    await prefs.remove("privacyMode");
    await prefs.remove("dailyDigestEnabled");
    emit(await AppState.getState());
  }
}