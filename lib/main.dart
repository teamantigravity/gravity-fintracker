import 'package:fintracker/app.dart';
import 'package:fintracker/bloc/cubit/app_cubit.dart';
import 'package:fintracker/dao/recurring_dao.dart';
import 'package:fintracker/helpers/db.helper.dart';
import 'package:fintracker/services/notification_service.dart';
import 'package:fintracker/services/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await getDBInstance();
  await NotificationService().init();
  await SubscriptionService().initialize();
  await RecurringDao().processDueTransactions();
  AppState appState = await AppState.getState();
  appState.isPro = SubscriptionService().isPro || appState.isPro;

  runApp(
      MultiBlocProvider(
          providers: [
            BlocProvider(create: (_)=>AppCubit(appState))
          ],
          child: const App()
      )
  );
}


