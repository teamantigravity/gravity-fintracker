import 'package:fintracker/bloc/cubit/app_cubit.dart';
import 'package:fintracker/screens/lock/app_lock_gate.dart';
import 'package:fintracker/screens/main.screen.dart';
import 'package:fintracker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          final platformBrightness = MediaQuery.of(context).platformBrightness;
          final theme = AppTheme.getTheme(state.themeMode, platformBrightness, seedColor: Color(state.themeColor));
          final isDark = theme.brightness == Brightness.dark;

          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: theme.scaffoldBackgroundColor,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ));

          return MaterialApp(
            title: 'Gravity Fintracker',
            debugShowCheckedModeBanner: false,
            theme: theme,
            home: AppLockGate(
              appLockEnabled: state.appLockEnabled,
              child: const MainScreen(),
            ),
            localizationsDelegates: const [
              GlobalWidgetsLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
            ],
          );
        });
  }
}