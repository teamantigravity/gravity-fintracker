import 'package:currency_picker/currency_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fintracker/bloc/cubit/app_cubit.dart';
import 'package:fintracker/config/constants.dart';
import 'package:fintracker/helpers/color.helper.dart';
import 'package:fintracker/helpers/db.helper.dart';
import 'package:fintracker/screens/premium/paywall.screen.dart';
import 'package:fintracker/screens/premium/privacy_dashboard.screen.dart';
import 'package:fintracker/services/backup_service.dart';
import 'package:fintracker/services/pin_service.dart';
import 'package:fintracker/theme/app_theme.dart';
import 'package:fintracker/widgets/buttons/button.dart';
import 'package:fintracker/widgets/dialog/confirm.modal.dart';
import 'package:fintracker/widgets/dialog/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_auth/local_auth.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricAvailable = false;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _checkPin();
  }

  Future<void> _checkBiometrics() async {
    try {
      bool available = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (mounted) setState(() => _biometricAvailable = available);
    } catch (_) {}
  }

  Future<void> _checkPin() async {
    try {
      bool hasPin = await PinService().hasPin();
      if (mounted) setState(() => _hasPin = hasPin);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
        appBar: AppBar(
          title: const Text("Settings"),
        ),
        body: BlocBuilder<AppCubit, AppState>(
          builder: (context, state) {
            return ListView(
              children: [
                // PROFILE SECTION
                _SectionHeader(title: "Profile"),
                ListTile(
                  onTap: () {
                    showDialog(context: context, builder: (context) {
                      TextEditingController controller = TextEditingController(text: context.read<AppCubit>().state.username);
                      return AlertDialog(
                        title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("What should we call you?", style: theme.textTheme.bodyLarge!.apply(color: ColorHelper.darken(theme.textTheme.bodyLarge!.color ?? theme.colorScheme.onSurface), fontWeightDelta: 1)),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: controller,
                              decoration: InputDecoration(
                                  label: const Text("Name"),
                                  hintText: "Enter your name",
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
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter name")));
                                      } else {
                                        context.read<AppCubit>().updateUsername(controller.text);
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    height: 45,
                                    label: "Save",
                                  )
                              )
                            ],
                          )
                        ],
                      );
                    });
                  },
                  leading: const CircleAvatar(child: Icon(Symbols.person)),
                  title: Text('Name', style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text(state.username ?? 'Guest', style: theme.textTheme.bodySmall?.apply(color: Colors.grey, overflow: TextOverflow.ellipsis)),
                ),
                ListTile(
                  onTap: () {
                    showCurrencyPicker(context: context, onSelect: (Currency currency) {
                      context.read<AppCubit>().updateCurrency(currency.code);
                    });
                  },
                  leading: Builder(builder: (context) {
                    Currency? currency = state.currency != null ? CurrencyService().findByCode(state.currency!) : null;
                    return CircleAvatar(child: Text(currency?.symbol ?? '\$'));
                  }),
                  title: Text('Currency', style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Builder(builder: (context) {
                    Currency? currency = state.currency != null ? CurrencyService().findByCode(state.currency!) : null;
                    return Text(currency?.name ?? 'Not set', style: theme.textTheme.bodySmall?.apply(color: Colors.grey, overflow: TextOverflow.ellipsis));
                  }),
                ),

                // APPEARANCE SECTION
                _SectionHeader(title: "Appearance"),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Symbols.palette)),
                  title: Text('Theme', style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text(
                    _themeModeName(state.themeMode),
                    style: theme.textTheme.bodySmall?.apply(color: Colors.grey),
                  ),
                  onTap: () => _showThemeSelector(context, state.themeMode),
                ),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Symbols.format_paint)),
                  title: Text('Accent Color', style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ColorDot(color: Color(state.themeColor), selected: true),
                      const SizedBox(width: 8),
                      ..._accentColors.where((c) => c.toARGB32() != state.themeColor).take(4).map((c) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _ColorDot(
                              color: c,
                              selected: false,
                              onTap: () => context.read<AppCubit>().updateThemeColor(c.toARGB32()),
                            ),
                          )),
                    ],
                  ),
                ),

                // SECURITY SECTION
                _SectionHeader(title: "Security"),
                if (AppConstants.enableBiometricLock && (_biometricAvailable || _hasPin))
                  SwitchListTile(
                    secondary: CircleAvatar(
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      child: Icon(Symbols.fingerprint, color: colorScheme.primary),
                    ),
                    title: Text('App Lock', style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                    subtitle: Text(
                      "Require biometric or PIN to open app",
                      style: theme.textTheme.bodySmall?.apply(color: Colors.grey),
                    ),
                    value: state.appLockEnabled,
                    onChanged: (value) async {
                      if (value) {
                        if (_biometricAvailable) {
                          try {
                            bool authenticated = await _localAuth.authenticate(
                              localizedReason: 'Verify your identity to enable app lock',
                            );
                            if (authenticated && context.mounted) {
                              context.read<AppCubit>().updateAppLock(true);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Biometric error: $e")),
                              );
                            }
                          }
                        } else if (_hasPin) {
                          context.read<AppCubit>().updateAppLock(true);
                        }
                      } else {
                        context.read<AppCubit>().updateAppLock(false);
                      }
                    },
                  ),
                if (AppConstants.enableBiometricLock)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      child: Icon(Symbols.pin, color: colorScheme.primary),
                    ),
                    title: Text(_hasPin ? 'Change PIN' : 'Set PIN', style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                    subtitle: Text(_hasPin ? 'Update your fallback PIN' : 'Set a PIN fallback for app lock', style: theme.textTheme.bodySmall?.apply(color: Colors.grey)),
                    onTap: () => _showPinDialog(context),
                  ),

                // PRIVACY SECTION
                _SectionHeader(title: "Privacy"),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
                    child: const Icon(Symbols.verified_user, color: Color(0xFF2E7D32)),
                  ),
                  title: Text('Privacy Dashboard', style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text("Score: 100% — Zero tracking", style: theme.textTheme.bodySmall?.apply(color: const Color(0xFF2E7D32))),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyDashboardScreen()),
                    );
                  },
                ),

                // DATA SECTION
                _SectionHeader(title: "Data"),
                ListTile(
                  onTap: () async {
                    if (!context.mounted) return;
                    ConfirmModal.showConfirmDialog(
                        context, title: "Export JSON Backup?",
                        content: const Text("Export all data to a JSON backup file"),
                        onConfirm: () async {
                          Navigator.of(context).pop();
                          final path = await FilePicker.platform.saveFile(
                            dialogTitle: "Save JSON backup",
                            fileName: "fintracker-backup.json",
                            type: FileType.custom,
                            allowedExtensions: ["json"],
                          );
                          if (path == null || path.isEmpty || !context.mounted) return;

                          LoadingModal.showLoadingDialog(context, content: const Text("Exporting..."));
                          try {
                            final value = await export(filePath: path);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved to $value")));
                            }
                          } catch (err) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Export failed")));
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
                  leading: const CircleAvatar(child: Icon(Symbols.download)),
                  title: Text('Export JSON', style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text("Full backup to JSON file", style: theme.textTheme.bodySmall?.apply(color: Colors.grey)),
                ),
                ListTile(
                  onTap: () async {
                    if (!context.mounted) return;
                    ConfirmModal.showConfirmDialog(
                        context, title: "Export CSV?",
                        content: const Text("Export all transactions to a CSV spreadsheet"),
                        onConfirm: () async {
                          Navigator.of(context).pop();
                          final path = await FilePicker.platform.saveFile(
                            dialogTitle: "Save CSV export",
                            fileName: "gravity-fintracker.csv",
                            type: FileType.custom,
                            allowedExtensions: ["csv"],
                          );
                          if (path == null || path.isEmpty || !context.mounted) return;

                          LoadingModal.showLoadingDialog(context, content: const Text("Exporting CSV..."));
                          try {
                            final value = await exportCsv(filePath: path);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved to $value")));
                            }
                          } catch (err) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CSV export failed")));
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
                  leading: const CircleAvatar(child: Icon(Symbols.table_chart)),
                  title: Text('Export CSV', style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text("Spreadsheet for analysis", style: theme.textTheme.bodySmall?.apply(color: Colors.grey)),
                ),
                ListTile(
                  onTap: () async {
                    try {
                      FilePickerResult? pick = await FilePicker.platform.pickFiles(
                          dialogTitle: "Pick backup file",
                          allowMultiple: false,
                          allowCompression: false,
                          type: FileType.custom,
                          allowedExtensions: ["json"]
                      );
                      if (pick == null || pick.files.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select file")));
                        }
                        return;
                      }
                      PlatformFile file = pick.files.first;
                      if (file.path == null || file.path!.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selected file has no path")));
                        }
                        return;
                      }
                      if (context.mounted) {
                        ConfirmModal.showConfirmDialog(
                            context, title: "Import Backup?",
                            content: const Text("All existing data will be replaced with the backup."),
                            onConfirm: () async {
                              Navigator.of(context).pop();
                              LoadingModal.showLoadingDialog(context, content: const Text("Importing..."));
                              try {
                                await import(file.path!);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Successfully imported")));
                                  Navigator.of(context).pop();
                                }
                              } catch (err) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Import failed")));
                                  Navigator.of(context).pop();
                                }
                              }
                            },
                            onCancel: () => Navigator.of(context).pop()
                        );
                      }
                    } catch (err) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Import failed")));
                      }
                    }
                  },
                  leading: const CircleAvatar(child: Icon(Symbols.upload)),
                  title: Text('Import', style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text("Restore from JSON backup", style: theme.textTheme.bodySmall?.apply(color: Colors.grey)),
                ),
                ListTile(
                  onTap: () async {
                    final password = await _showPasswordDialog(context, title: 'Export Encrypted Backup', confirm: true);
                    if (password == null || password.isEmpty) return;
                    if (!context.mounted) return;
                    final path = await FilePicker.platform.saveFile(
                      dialogTitle: "Save encrypted backup",
                      fileName: "fintracker-encrypted-backup.json",
                      type: FileType.custom,
                      allowedExtensions: ["json"],
                    );
                    if (path == null || path.isEmpty || !context.mounted) return;

                    LoadingModal.showLoadingDialog(context, content: const Text("Encrypting..."));
                    try {
                      final value = await BackupService.exportEncrypted(password, filePath: path);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved to $value")));
                        Navigator.of(context).pop();
                      }
                    } catch (err) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Export failed")));
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  leading: const CircleAvatar(child: Icon(Symbols.lock)),
                  title: Text('Export Encrypted', style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text("Password-protected backup", style: theme.textTheme.bodySmall?.apply(color: Colors.grey)),
                ),
                ListTile(
                  onTap: () async {
                    try {
                      FilePickerResult? pick = await FilePicker.platform.pickFiles(
                        dialogTitle: "Pick encrypted backup",
                        allowMultiple: false,
                        allowCompression: false,
                        type: FileType.custom,
                        allowedExtensions: ["json"],
                      );
                      if (pick == null || pick.files.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select file")));
                        }
                        return;
                      }
                      PlatformFile file = pick.files.first;
                      if (file.path == null || file.path!.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selected file has no path")));
                        }
                        return;
                      }
                      if (!context.mounted) return;
                      final password = await _showPasswordDialog(context, title: 'Import Encrypted Backup', confirm: false);
                      if (password == null || password.isEmpty) return;
                      if (!context.mounted) return;
                      LoadingModal.showLoadingDialog(context, content: const Text("Decrypting..."));
                      await BackupService.importEncrypted(file.path!, password);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Successfully imported")));
                        Navigator.of(context).pop();
                      }
                    } catch (err) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Import failed")));
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  leading: const CircleAvatar(child: Icon(Symbols.lock_open)),
                  title: Text('Import Encrypted', style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text("Restore password-protected backup", style: theme.textTheme.bodySmall?.apply(color: Colors.grey)),
                ),

                // PREMIUM SECTION
                _SectionHeader(title: "Premium"),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withOpacity(0.1),
                        colorScheme.tertiary.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Symbols.workspace_premium, color: colorScheme.primary, fill: 1),
                    ),
                    title: Text(
                      state.isPro ? 'Gravity Pro' : 'Upgrade to Pro',
                      style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                    subtitle: Text(
                      state.isPro
                          ? "Sync, recurring, advanced reports"
                          : "E2E sync, multi-device, and more",
                      style: theme.textTheme.bodySmall?.apply(color: Colors.grey),
                    ),
                    trailing: state.isPro
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text("Active", style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.w600)),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PaywallScreen()),
                      );
                    },
                  ),
                ),

                // ABOUT SECTION
                _SectionHeader(title: "About"),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Symbols.info)),
                  title: Text('Version', style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text(AppConstants.appVersion, style: theme.textTheme.bodySmall?.apply(color: Colors.grey)),
                ),
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
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              if (confirm) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
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
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
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
                  labelText: 'PIN',
                  hintText: '4-6 digits',
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
                  labelText: 'Confirm PIN',
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
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN must be at least 4 digits')));
                        return;
                      }
                      if (pinController.text != confirmController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs do not match')));
                        return;
                      }
                      await PinService().setPin(pinController.text);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN set')));
                        _checkPin();
                      }
                    },
                    height: 45,
                    label: 'Save',
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
        return "Light";
      case AppThemeMode.dark:
        return "Dark";
      case AppThemeMode.amoled:
        return "AMOLED Dark";
      case AppThemeMode.system:
        return "System";
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text("Choose Theme", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _ThemeOption(
                  icon: Symbols.brightness_auto,
                  label: "System",
                  subtitle: "Follow device settings",
                  isSelected: current == AppThemeMode.system,
                  onTap: () {
                    context.read<AppCubit>().updateThemeMode(AppThemeMode.system);
                    Navigator.pop(context);
                  },
                ),
                _ThemeOption(
                  icon: Symbols.light_mode,
                  label: "Light",
                  subtitle: "Clean and bright",
                  isSelected: current == AppThemeMode.light,
                  onTap: () {
                    context.read<AppCubit>().updateThemeMode(AppThemeMode.light);
                    Navigator.pop(context);
                  },
                ),
                _ThemeOption(
                  icon: Symbols.dark_mode,
                  label: "Dark",
                  subtitle: "Easy on the eyes",
                  isSelected: current == AppThemeMode.dark,
                  onTap: () {
                    context.read<AppCubit>().updateThemeMode(AppThemeMode.dark);
                    Navigator.pop(context);
                  },
                ),
                _ThemeOption(
                  icon: Symbols.nights_stay,
                  label: "AMOLED Dark",
                  subtitle: "True black, saves battery",
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

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
      ),
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
    return ListTile(
      leading: Icon(icon, fill: 1, color: isSelected ? colorScheme.primary : null),
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.apply(color: Colors.grey)),
      trailing: isSelected ? Icon(Symbols.check_circle, color: colorScheme.primary, fill: 1) : null,
      onTap: onTap,
    );
  }
}

const List<Color> _accentColors = [
  Color(0xFF6750A4),
  Color(0xFF006A60),
  Color(0xFF006D37),
  Color(0xFF005AC1),
  Color(0xFF984061),
  Color(0xFF934B00),
];

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
              color: color.withOpacity(0.3),
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
