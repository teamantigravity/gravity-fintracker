import 'package:fintracker/app.dart';
import 'package:fintracker/bloc/cubit/app_cubit.dart';
import 'package:fintracker/dao/recurring_dao.dart';
import 'package:fintracker/helpers/db.helper.dart';
import 'package:fintracker/helpers/platform_database.dart';
import 'package:fintracker/services/daily_digest_service.dart';
import 'package:fintracker/services/desktop_service.dart';
import 'package:fintracker/services/notification_service.dart';
import 'package:fintracker/services/subscription_service.dart';
import 'package:fintracker/services/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureDatabaseInitialized();
  await getDBInstance();

  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }

  try {
    await SubscriptionService().initialize();
  } catch (e) {
    debugPrint('Subscription init failed: $e');
  }

  try {
    await RecurringDao().processDueTransactions();
  } catch (e) {
    debugPrint('Recurring processing failed: $e');
  }

  try {
    await SyncService().initialize();
  } catch (e) {
    debugPrint('Sync init failed: $e');
  }

  try {
    await DesktopService.initialize();
  } catch (e) {
    debugPrint('Desktop service init failed: $e');
  }

  AppState appState = await AppState.getState();

  if (appState.dailyDigestEnabled) {
    try {
      await DailyDigestService.schedule();
    } catch (e) {
      debugPrint('Daily digest schedule failed: $e');
    }
  }

  runApp(
      MultiBlocProvider(
          providers: [
            BlocProvider(create: (_)=>AppCubit(appState))
          ],
          child: const App()
      )
  );
}


