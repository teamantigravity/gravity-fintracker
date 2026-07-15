import 'package:fintracker/bloc/cubit/app_cubit.dart';
import 'package:fintracker/config/constants.dart';
import 'package:fintracker/model/payment.model.dart';
import 'package:fintracker/screens/main.screen.dart';
import 'package:fintracker/screens/payment_form.screen.dart';
import 'package:fintracker/services/pin_service.dart';
import 'package:fintracker/services/receipt_scanner_service.dart';
import 'package:fintracker/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:local_auth/local_auth.dart';

class NewPaymentIntent extends Intent { const NewPaymentIntent(); }
class NavigateToTabIntent extends Intent {
  final int index;
  const NavigateToTabIntent(this.index);
}

class App extends StatelessWidget {
  const App({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<MainScreenState> mainScreenKey = GlobalKey<MainScreenState>();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
        builder: (context, state) {
          final platformBrightness = MediaQuery.of(context).platformBrightness;
          final theme = AppTheme.getTheme(state.themeMode, platformBrightness, themeColor: state.themeColor);
          final isDark = theme.brightness == Brightness.dark;

          SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: theme.scaffoldBackgroundColor,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ));

          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: theme,
            navigatorKey: navigatorKey,
            home: AppLockWrapper(child: MainScreen(key: mainScreenKey)),
            localizationsDelegates: const [
              GlobalWidgetsLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
            ],
            builder: (context, child) {
              return Shortcuts(
                shortcuts: const {
                  SingleActivator(LogicalKeyboardKey.keyN, control: true): NewPaymentIntent(),
                  SingleActivator(LogicalKeyboardKey.keyN, meta: true): NewPaymentIntent(),
                  SingleActivator(LogicalKeyboardKey.digit1, control: true): NavigateToTabIntent(0),
                  SingleActivator(LogicalKeyboardKey.digit1, meta: true): NavigateToTabIntent(0),
                  SingleActivator(LogicalKeyboardKey.digit2, control: true): NavigateToTabIntent(1),
                  SingleActivator(LogicalKeyboardKey.digit2, meta: true): NavigateToTabIntent(1),
                  SingleActivator(LogicalKeyboardKey.digit3, control: true): NavigateToTabIntent(2),
                  SingleActivator(LogicalKeyboardKey.digit3, meta: true): NavigateToTabIntent(2),
                  SingleActivator(LogicalKeyboardKey.digit4, control: true): NavigateToTabIntent(3),
                  SingleActivator(LogicalKeyboardKey.digit4, meta: true): NavigateToTabIntent(3),
                  SingleActivator(LogicalKeyboardKey.digit5, control: true): NavigateToTabIntent(4),
                  SingleActivator(LogicalKeyboardKey.digit5, meta: true): NavigateToTabIntent(4),
                },
                child: Actions(
                  actions: {
                    NewPaymentIntent: CallbackAction<NewPaymentIntent>(
                      onInvoke: (_) {
                        App.navigatorKey.currentState?.push(
                          MaterialPageRoute(builder: (_) => const PaymentForm(type: PaymentType.debit)),
                        );
                        return null;
                      },
                    ),
                    NavigateToTabIntent: CallbackAction<NavigateToTabIntent>(
                      onInvoke: (intent) {
                        App.mainScreenKey.currentState?.navigateTo(intent.index);
                        return null;
                      },
                    ),
                  },
                  child: Focus(
                    autofocus: true,
                    canRequestFocus: true,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              );
            },
          );
        });
  }
}

class AppLockWrapper extends StatefulWidget {
  final Widget child;
  const AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper> with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _showPinInput = false;
  bool _isAuthenticating = false;
  bool _hasResumedOnce = false;
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isLocked = context.read<AppCubit>().state.appLockEnabled;
    if (_isLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkLock());
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    ReceiptScannerService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      ReceiptScannerService.dispose();
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    // The first resumed event fires during launch and is already handled by
    // the addPostFrameCallback in initState. Calling _checkLock again can
    // trigger a second biometric prompt that confuses the plugin and locks
    // the user out.
    if (!_hasResumedOnce) {
      _hasResumedOnce = true;
      return;
    }
    _checkLock();
  }

  Future<void> _checkLock() async {
    if (_isAuthenticating) return;

    final appState = context.read<AppCubit>().state;
    if (!appState.appLockEnabled) {
      if (mounted) setState(() => _isLocked = false);
      return;
    }

    if (mounted) setState(() => _isLocked = true);

    _isAuthenticating = true;
    final LocalAuthentication localAuth = LocalAuthentication();
    try {
      bool authenticated = await localAuth.authenticate(
        localizedReason: 'Unlock ${AppConstants.appName}',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (authenticated && mounted) {
        setState(() => _isLocked = false);
        return;
      }
    } catch (e) {
      debugPrint('Biometric unlock failed: $e');
    } finally {
      _isAuthenticating = false;
    }

    try {
      if (await PinService().hasPin() && mounted) {
        setState(() => _showPinInput = true);
        return;
      }
    } catch (e) {
      debugPrint('PIN read failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not read PIN: $e')),
        );
      }
    }

    // No biometric and no PIN: lock is not enforceable, so unlock
    if (mounted) {
      setState(() => _isLocked = false);
    }
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text;
    if (pin.isEmpty) return;
    try {
      final valid = await PinService().verifyPin(pin);
      if (valid && mounted) {
        setState(() => _isLocked = false);
        _pinController.clear();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect PIN')),
          );
          _pinController.clear();
        }
      }
    } catch (e) {
      debugPrint('PIN verification failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PIN verification failed: $e')),
        );
        _pinController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocked) return widget.child;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('Locked', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              if (!_showPinInput)
                FilledButton(
                  onPressed: _checkLock,
                  child: const Text('Unlock'),
                ),
              if (_showPinInput) ...[
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Enter PIN',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    counterText: '',
                  ),
                  onSubmitted: (_) => _verifyPin(),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _verifyPin,
                  child: const Text('Verify PIN'),
                ),
                TextButton(
                  onPressed: () => setState(() => _showPinInput = false),
                  child: const Text('Use biometric'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}