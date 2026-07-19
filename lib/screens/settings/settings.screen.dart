import 'package:currency_picker/currency_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fintracker/bloc/cubit/app_cubit.dart';
import 'package:fintracker/config/constants.dart';
import 'package:fintracker/helpers/color.helper.dart';
import 'package:fintracker/helpers/db.helper.dart';
import 'package:fintracker/screens/premium/paywall.screen.dart';
import 'package:fintracker/screens/premium/privacy_dashboard.screen.dart';
import 'package:fintracker/services/backup_service.dart';
import 'package:fintracker/services/daily_digest_service.dart';
import 'package:fintracker/services/pin_service.dart';
import 'package:fintracker/theme/app_theme.dart';
import 'package:fintracker/ui/prism.dart';
import 'package:fintracker/widgets/buttons/button.dart';
import 'package:fintracker/widgets/dialog/confirm.modal.dart';
import 'package:fintracker/widgets/dialog/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fintracker/theme/prism_colors.dart';
import 'package:fintracker/config/strings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricAvailable = false;
  bool _hasPin = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _checkPin();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = '${info.version}+${info.buildNumber}');
  }

  Future<void> _checkBiometrics() async {
    try {
      final bool available = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (mounted) setState(() => _biometricAvailable = available);
    } catch (e) {
      debugPrint('Biometric check failed: $e');
    }
  }

  Future<void> _checkPin() async {
    try {
      final bool hasPin = await PinService().hasPin();
      if (mounted) setState(() => _hasPin = hasPin);
    } catch (e) {
      debugPrint('PIN check failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
        appBar: AppBar(
          title: const Text(Strings.settings),
        ),
        body: BlocBuilder<AppCubit, AppState>(
          builder: (context, state) {
            return ListView(
              children: [
                // PROFILE SECTION
                PrismSection(
                  title: Strings.profile,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                PrismListTile(
                  onTap: () {
                    showDialog(context: context, builder: (context) {
                      final TextEditingController controller = TextEditingController(text: context.read<AppCubit>().state.username);
                      return AlertDialog(
                        title: const Text(Strings.profile, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(Strings.whatShouldWeCallYou, style: theme.textTheme.bodyLarge?.apply(color: ColorHelper.darken(theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface), fontWeightDelta: 1)),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: controller,
                              decoration: InputDecoration(
                                  label: const Text(Strings.name),
                                  hintText: Strings.enterYourName,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15)
                              ),
                            )
                          ],
                        ),
                        actions: [
                          Row(
                            children: [
                              Expanded(
                                  child: AppButton(
                                    onPressed: () {
                                      if (controller.text.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.pleaseEnterName)));
                                      } else {
                                        context.read<AppCubit>().updateUsername(controller.text);
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    height: 45,
                                    label: Strings.save,
                                  )
                              )
                            ],
                          )
                        ],
                      );
                    });
                  },
                  icon: Symbols.person,
                  title: Text(Strings.name, style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text(state.username ?? 'Guest', style: theme.textTheme.bodySmall?.apply(color: Colors.grey, overflow: TextOverflow.ellipsis)),
                ),
                PrismListTile(
                  onTap: () {
                    showCurrencyPicker(context: context, onSelect: (Currency currency) {
                      context.read<AppCubit>().updateCurrency(currency.code);
                    });
                  },
                  leading: Builder(builder: (context) {
                    final currencyCode = state.currency;
                    final currency = currencyCode != null ? CurrencyService().findByCode(currencyCode) : null;
                    return PrismAvatar(
                      child: Text(
                        currency?.symbol ?? '\$',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.primary),
                      ),
                    );
                  }),
                  title: Text(Strings.currency, style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Builder(builder: (context) {
                    final currencyCode = state.currency;
                    final currency = currencyCode != null ? CurrencyService().findByCode(currencyCode) : null;
                    return Text(currency?.name ?? 'Not set', style: theme.textTheme.bodySmall?.apply(color: Colors.grey, overflow: TextOverflow.ellipsis));
                  }),
                ),
                ]),

                // APPEARANCE SECTION
                PrismSection(
                  title: 'Appearance',
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                PrismListTile(
                  icon: Symbols.palette,
                  title: Text(Strings.theme, style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text(
                    _themeModeName(state.themeMode),
                    style: theme.textTheme.bodySmall?.apply(color: Colors.grey),
                  ),
                  onTap: () => _showThemeSelector(context, state.themeMode),
                ),
                PrismListTile(
                  icon: Symbols.format_paint,
                  title: Text(Strings.accentColor, style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ColorDot(color: Color(state.themeColor), selected: true),
                      const SizedBox(width: 8),
                      ..._accentColors.where((c) => c.toARGB32() != state.themeColor).take(4).map((c) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _ColorDot(
                              color: c,
                              onTap: () => context.read<AppCubit>().updateThemeColor(c.toARGB32()),
                            ),
                          )),
                    ],
                  ),
                ),
                ]),

                // SECURITY SECTION
                PrismSection(
                  title: 'Security',
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                if (AppConstants.enableBiometricLock && (_biometricAvailable || _hasPin))
                  PrismListTile(
                    icon: Symbols.fingerprint,
                    iconColor: colorScheme.primary,
                    title: Text(Strings.appLock, style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                    subtitle: Text(
                      Strings.requireBiometricOrPinToOpen,
                      style: theme.textTheme.bodySmall?.apply(color: Colors.grey),
                    ),
                    trailing: Switch(
                      value: state.appLockEnabled,
                      onChanged: (value) { _toggleAppLock(value); },
                    ),
                  ),
                if (AppConstants.enableBiometricLock)
                  PrismListTile(
                    icon: Symbols.pin,
                    title: Text(_hasPin ? 'Change PIN' : 'Set PIN', style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                    subtitle: Text(_hasPin ? 'Update your fallback PIN' : 'Set a PIN fallback for app lock', style: theme.textTheme.bodySmall?.apply(color: Colors.grey)),
                    onTap: () => _showPinDialog(context),
                  ),
                ]),

                // PRIVACY SECTION
                PrismSection(
                  title: 'Privacy',
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                PrismListTile(
                  icon: Symbols.verified_user,
                  iconColor: PrismColors.income,
                  title: Text(Strings.privacyDashboard, style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text(Strings.score100ZeroTracking, style: theme.textTheme.bodySmall?.apply(color: PrismColors.income)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      PrismPageRoute(builder: (_) => const PrivacyDashboardScreen()),
                    );
                  },
                ),
                PrismListTile(
                  icon: Symbols.visibility_off,
                  title: Text(Strings.privacyMode, style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text(Strings.hideAllAmountsWith, style: theme.textTheme.bodySmall?.apply(color: Colors.grey)),
                  trailing: Switch(
                    value: state.privacyMode,
                    onChanged: (value) { context.read<AppCubit>().updatePrivacyMode(value); },
                  ),
                ),
                PrismListTile(
                  icon: Symbols.notifications_active,
                  title: Text(Strings.dailyDigest, style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text(Strings.morningNotificationWithYourSpendingSnapshot, style: theme.textTheme.bodySmall?.apply(color: Colors.grey)),
                  trailing: Switch(
                    value: state.dailyDigestEnabled,
                    onChanged: (value) { _toggleDailyDigest(value); },
                  ),
                ),
                ]),

                // DATA SECTION
                PrismSection(
                  title: 'Data',
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                PrismListTile(
                  onTap: () async {
                    if (!context.mounted) return;
                    ConfirmModal.showConfirmDialog(
                        context, title: 'Export JSON Backup?',
                        content: const Text(Strings.exportAllDataToAJson),
                        onConfirm: () async {
                          Navigator.of(context).pop();
                          final path = await FilePicker.platform.saveFile(
                            dialogTitle: 'Save JSON backup',
                            fileName: 'fintracker-backup.json',
                            type: FileType.custom,
                            allowedExtensions: ['json'],
                          );
                          if (path == null || path.isEmpty || !context.mounted) return;

                          LoadingModal.showLoadingDialog(context, content: const Text(Strings.exporting));
                          try {
                            final value = await export(filePath: path);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Strings.savedToFmt(value))));
                            }
                          } catch (err) {
                            debugPrint('JSON export error: $err');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.exportFailed)));
                            }
                          } finally {
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          }
                        },
                        onCancel: () => Navigator.of(context).pop()
                    );
                  },
                  icon: Symbols.download,
                  title: Text(Strings.exportJson, style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text(Strings.fullBackupToJsonFile, style: theme.textTheme.bodySmall?.apply(color: Colors.grey)),
                ),
                PrismListTile(
                  onTap: () async {
                    if (!context.mounted) return;
                    ConfirmModal.showConfirmDialog(
                        context, title: 'Export CSV?',
                        content: const Text(Strings.exportAllTransactionsToACsv),
                        onConfirm: () async {
                          Navigator.of(context).pop();
                          final path = await FilePicker.platform.saveFile(
                            dialogTitle: 'Save CSV export',
                            fileName: 'gravity-fintracker.csv',
                            type: FileType.custom,
                            allowedExtensions: ['csv'],
                          );
                          if (path == null || path.isEmpty || !context.mounted) return;

                          LoadingModal.showLoadingDialog(context, content: const Text(Strings.exportingCsv));
                          try {
                            final value = await exportCsv(filePath: path);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Strings.savedToFmt(value))));
                            }
                          } catch (err) {
                            debugPrint('CSV export error: $err');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.csvExportFailed)));
                            }
                          } finally {
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          }
                        },
                        onCancel: () => Navigator.of(context).pop()
                    );
                  },
                  icon: Symbols.table_chart,
                  title: Text(Strings.exportCsv, style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text(Strings.spreadsheetForAnalysis, style: theme.textTheme.bodySmall?.apply(color: Colors.grey)),
                ),
                PrismListTile(
                  onTap: () async {
                    try {
                      final FilePickerResult? pick = await FilePicker.platform.pickFiles(
                          dialogTitle: 'Pick backup file',
                          allowCompression: false,
                          type: FileType.custom,
                          allowedExtensions: ['json']
                      );
                      if (pick == null || pick.files.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.pleaseSelectFile)));
                        }
                        return;
                      }
                      final file = pick.files.first;
                      final path = file.path;
                      if (path == null || path.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.selectedFileHasNoPath)));
                        }
                        return;
                      }
                      if (context.mounted) {
                        ConfirmModal.showConfirmDialog(
                            context, title: 'Import Backup?',
                            content: const Text(Strings.allExistingDataWillBeReplaced),
                            onConfirm: () async {
                              Navigator.of(context).pop();
                              LoadingModal.showLoadingDialog(context, content: const Text(Strings.importing));
                              try {
                                await import(path);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.successfullyImported)));
                                  Navigator.of(context).pop();
                                }
                              } catch (err) {
                                debugPrint('JSON import error: $err');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.importFailed)));
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                            onCancel: () => Navigator.of(context).pop()
                        );
                      }
                    } catch (err) {
                      debugPrint('File picker import error: $err');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.importFailed)));
                      }
                    }
                  },
                  icon: Symbols.upload,
                  title: Text(Strings.import, style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text(Strings.restoreFromJsonBackup, style: theme.textTheme.bodySmall?.apply(color: Colors.grey)),
                ),
                PrismListTile(
                  onTap: () async {
                    final password = await _showPasswordDialog(context, title: 'Export Encrypted Backup', confirm: true);
                    if (password == null || password.isEmpty) return;
                    if (!context.mounted) return;
                    final path = await FilePicker.platform.saveFile(
                      dialogTitle: 'Save encrypted backup',
                      fileName: 'fintracker-encrypted-backup.json',
                      type: FileType.custom,
                      allowedExtensions: ['json'],
                    );
                    if (path == null || path.isEmpty || !context.mounted) return;

                    LoadingModal.showLoadingDialog(context, content: const Text(Strings.encrypting));
                    try {
                      final value = await BackupService.exportEncrypted(password, filePath: path);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Strings.savedToFmt(value))));
                        Navigator.of(context).pop();
                      }
                    } catch (err) {
                      debugPrint('Encrypted export error: $err');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.exportFailed)));
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  icon: Symbols.lock,
                  title: Text(Strings.exportEncrypted, style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text(Strings.passwordProtectedBackup, style: theme.textTheme.bodySmall?.apply(color: Colors.grey)),
                ),
                PrismListTile(
                  onTap: () async {
                    try {
                      final FilePickerResult? pick = await FilePicker.platform.pickFiles(
                        dialogTitle: 'Pick encrypted backup',
                        allowCompression: false,
                        type: FileType.custom,
                        allowedExtensions: ['json'],
                      );
                      if (pick == null || pick.files.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.pleaseSelectFile)));
                        }
                        return;
                      }
                      final file = pick.files.first;
                      final path = file.path;
                      if (path == null || path.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.selectedFileHasNoPath)));
                        }
                        return;
                      }
                      if (!context.mounted) return;
                      final password = await _showPasswordDialog(context, title: 'Import Encrypted Backup', confirm: false);
                      if (password == null || password.isEmpty) return;
                      if (!context.mounted) return;
                      LoadingModal.showLoadingDialog(context, content: const Text(Strings.decrypting));
                      await BackupService.importEncrypted(path, password);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.successfullyImported)));
                        Navigator.of(context).pop();
                      }
                    } catch (err) {
                      debugPrint('Encrypted import error: $err');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.importFailed)));
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  icon: Symbols.lock_open,
                  title: Text(Strings.importEncrypted, style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text(Strings.restorePasswordProtectedBackup, style: theme.textTheme.bodySmall?.apply(color: Colors.grey)),
                ),
                ]),

                // PREMIUM SECTION
                PrismSection(
                  title: 'Premium',
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                PrismCard(
                  isGlass: true,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.12),
                      colorScheme.tertiary.withValues(alpha: 0.06),
                    ],
                  ),
                  borderColor: colorScheme.primary.withValues(alpha: 0.2),
                  padding: EdgeInsets.zero,
                  child: PrismListTile(
                    icon: Symbols.workspace_premium,
                    title: Text(
                      state.isPro ? Strings.gravityPro : state.isPlus ? Strings.gravityPlus : Strings.upgrade,
                      style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                    subtitle: Text(
                      state.isPro
                          ? Strings.proDescription
                          : state.isPlus
                              ? Strings.plusDescription
                              : Strings.freeDescription,
                      style: theme.textTheme.bodySmall?.apply(color: Colors.grey),
                    ),
                    trailing: state.isPlus || state.isPro
                        ? const PrismChip(label: Strings.active, color: AppTheme.incomeColor)
                        : const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        PrismPageRoute(builder: (_) => const PaywallScreen()),
                      );
                    },
                  ),
                ),
                ]),

                // ABOUT SECTION
                PrismSection(
                  title: Strings.about,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                PrismListTile(
                  icon: Symbols.info,
                  title: Text(Strings.version, style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text(_version, style: theme.textTheme.bodySmall?.apply(color: Colors.grey)),
                ),
                ]),
                const SizedBox(height: 40),
              ],
            );
          },
        )
    );
  }

  Future<String?> _showPasswordDialog(BuildContext context, {required String title, required bool confirm}) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    return showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: Strings.password,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              if (confirm) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: Strings.confirmPassword,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    onPressed: () {
                      if (passwordController.text.isEmpty) return;
                      if (confirm && passwordController.text != confirmController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.passwordsDoNotMatch)));
                        return;
                      }
                      Navigator.of(context).pop(passwordController.text);
                    },
                    height: 45,
                    label: 'Confirm',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleAppLock(bool value) async {
    if (value) {
      if (_biometricAvailable) {
        try {
          final authenticated = await _localAuth.authenticate(
            localizedReason: Strings.verifyYourIdentityToEnableApp,
          );
          if (authenticated && mounted) {
            context.read<AppCubit>().updateAppLock(true);
          }
        } catch (e) {
          debugPrint('Biometric auth error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(Strings.biometricError)),
            );
          }
        }
      } else if (_hasPin) {
        context.read<AppCubit>().updateAppLock(true);
      }
    } else {
      context.read<AppCubit>().updateAppLock(false);
    }
  }

  Future<void> _toggleDailyDigest(bool value) async {
    context.read<AppCubit>().updateDailyDigest(value);
    if (value) {
      await DailyDigestService.schedule();
    } else {
      await DailyDigestService.cancel();
    }
  }

  void _showPinDialog(BuildContext context) {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_hasPin ? 'Change PIN' : 'Set PIN', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: Strings.pin,
                  hintText: Strings.s46Digits,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: Strings.confirmPin,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    onPressed: () async {
                      if (pinController.text.length < 4) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.pinMustBeAtLeast4)));
                        return;
                      }
                      if (pinController.text != confirmController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.pinsDoNotMatch)));
                        return;
                      }
                      try {
                        await PinService().setPin(pinController.text);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.pinSet)));
                          _checkPin();
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(Strings.pinSetFailed)));
                        }
                      }
                    },
                    height: 45,
                    label: Strings.save,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _themeModeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.amoled:
        return 'AMOLED Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }

  void _showThemeSelector(BuildContext context, AppThemeMode current) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(Strings.chooseTheme, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _ThemeOption(
                  icon: Symbols.brightness_auto,
                  label: 'System',
                  subtitle: 'Follow device settings',
                  isSelected: current == AppThemeMode.system,
                  onTap: () {
                    context.read<AppCubit>().updateThemeMode(AppThemeMode.system);
                    Navigator.pop(context);
                  },
                ),
                _ThemeOption(
                  icon: Symbols.light_mode,
                  label: 'Light',
                  subtitle: 'Clean and bright',
                  isSelected: current == AppThemeMode.light,
                  onTap: () {
                    context.read<AppCubit>().updateThemeMode(AppThemeMode.light);
                    Navigator.pop(context);
                  },
                ),
                _ThemeOption(
                  icon: Symbols.dark_mode,
                  label: 'Dark',
                  subtitle: 'Easy on the eyes',
                  isSelected: current == AppThemeMode.dark,
                  onTap: () {
                    context.read<AppCubit>().updateThemeMode(AppThemeMode.dark);
                    Navigator.pop(context);
                  },
                ),
                _ThemeOption(
                  icon: Symbols.nights_stay,
                  label: 'AMOLED Dark',
                  subtitle: 'True black, saves battery',
                  isSelected: current == AppThemeMode.amoled,
                  onTap: () {
                    context.read<AppCubit>().updateThemeMode(AppThemeMode.amoled);
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return PrismListTile(
      leading: Icon(icon, fill: 1, color: isSelected ? colorScheme.primary : null),
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.apply(color: Colors.grey)),
      trailing: isSelected ? Icon(Symbols.check_circle, color: colorScheme.primary, fill: 1) : null,
      onTap: onTap,
    );
  }
}

const List<Color> _accentColors = PrismColors.accentOptions;

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const _ColorDot({required this.color, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: selected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
      ),
    );
  }
}
