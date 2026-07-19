import 'package:fintracker/services/subscription_service.dart';
import 'package:fintracker/theme/app_theme.dart';
import 'package:fintracker/theme/prism_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  late String? username;
  late int themeColor;
  late String? currency;
  late AppThemeMode themeMode;
  late bool appLockEnabled;
  late bool isPlus;
  late bool isPro;
  late bool privacyMode;
  late bool dailyDigestEnabled;

  static Future<AppState> getState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? themeColor = prefs.getInt('themeColor');
    final String? username = prefs.getString('username');
    final String? currency = prefs.getString('currency');
    final String? themeModeStr = prefs.getString('themeMode');
    final bool? appLock = prefs.getBool('appLockEnabled');
    final bool? isPlus = prefs.getBool('isPlus');
    final bool? isPro = prefs.getBool('isPro');
    final bool? privacyMode = prefs.getBool('privacyMode');
    final bool? dailyDigest = prefs.getBool('dailyDigestEnabled');

    final AppState appState = AppState();
    appState.themeColor = themeColor ?? PrismColors.primary.toARGB32();
    appState.username = username;
    appState.currency = currency;
    appState.themeMode = _parseThemeMode(themeModeStr);
    appState.appLockEnabled = appLock ?? false;
    appState.isPro = (isPro ?? false) || SubscriptionService().isPro;
    appState.isPlus = (isPlus ?? false) || appState.isPro || SubscriptionService().isPlus;
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
  AppCubit(super.initialState);

  Future<void> updateUsername(String username) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    emit(await AppState.getState());
  }

  Future<void> updateCurrency(String currency) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
    emit(await AppState.getState());
  }

  Future<void> updateThemeColor(int color) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeColor', color);
    emit(await AppState.getState());
  }

  Future<void> updateThemeMode(AppThemeMode mode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
    emit(await AppState.getState());
  }

  Future<void> updateAppLock(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('appLockEnabled', enabled);
    emit(await AppState.getState());
  }

  Future<void> updatePlus(bool isPlus) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPlus', isPlus);
    if (!isPlus) await prefs.setBool('isPro', false);
    emit(await AppState.getState());
  }

  Future<void> updatePro(bool isPro) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPro', isPro);
    if (isPro) await prefs.setBool('isPlus', true);
    emit(await AppState.getState());
  }

  Future<void> updatePrivacyMode(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacyMode', enabled);
    emit(await AppState.getState());
  }

  Future<void> updateDailyDigest(bool enabled) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dailyDigestEnabled', enabled);
    emit(await AppState.getState());
  }

  Future<void> reset() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('currency');
    await prefs.remove('themeColor');
    await prefs.remove('username');
    await prefs.remove('themeMode');
    await prefs.remove('appLockEnabled');
    await prefs.remove('isPlus');
    await prefs.remove('isPro');
    await prefs.remove('privacyMode');
    await prefs.remove('dailyDigestEnabled');
    emit(await AppState.getState());
  }
}