import 'package:currency_picker/currency_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fintracker/bloc/cubit/app_cubit.dart';
import 'package:fintracker/config/constants.dart';
import 'package:fintracker/helpers/color.helper.dart';
import 'package:fintracker/helpers/db.helper.dart';
import 'package:fintracker/screens/premium/paywall.screen.dart';
import 'package:fintracker/screens/premium/privacy_dashboard.screen.dart';
import 'package:fintracker/services/biometric_service.dart';
import 'package:fintracker/theme/app_theme.dart';
import 'package:fintracker/widgets/buttons/button.dart';
import 'package:fintracker/widgets/dialog/confirm.modal.dart';
import 'package:fintracker/widgets/dialog/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BiometricService _biometrics = BiometricService();
  BiometricCapability _capability = BiometricCapability.unavailable;
  bool _capabilityChecked = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final capability = await _biometrics.getCapability();
    if (mounted) {
      setState(() {
        _capability = capability;
        _capabilityChecked = true;
      });
    }
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
                            Text("What should we call you?", style: theme.textTheme.bodyLarge!.apply(color: ColorHelper.darken(theme.textTheme.bodyLarge!.color!), fontWeightDelta: 1)),
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
                  leading: CircleAvatar(backgroundColor: Color(state.themeColor), child: const Icon(Symbols.colors, color: Colors.white)),
                  title: Text('Accent Color', style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text("Personalize with Google's brand colors", style: theme.textTheme.bodySmall?.apply(color: Colors.grey)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: AppTheme.accentOptions.map((color) {
                      final selected = state.themeColor == color.toARGB32();
                      return GestureDetector(
                        onTap: () => context.read<AppCubit>().updateThemeColor(color.toARGB32()),
                        child: Container(
                          margin: const EdgeInsets.only(left: 6),
                          width: selected ? 26 : 20,
                          height: selected ? 26 : 20,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: selected ? Border.all(color: colorScheme.onSurface.withOpacity(0.3), width: 2) : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // SECURITY SECTION
                if (_capabilityChecked && _capability != BiometricCapability.unavailable && AppConstants.enableBiometricLock) ...[
                  _SectionHeader(title: "Security"),
                  SwitchListTile(
                    secondary: CircleAvatar(
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      child: Icon(
                        _capability == BiometricCapability.biometric ? Symbols.fingerprint : Symbols.lock,
                        color: colorScheme.primary,
                      ),
                    ),
                    title: Text('App Lock', style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                    subtitle: Text(
                      _capability == BiometricCapability.biometric
                          ? "Require biometric to open app"
                          : "Require device PIN/pattern to open app",
                      style: theme.textTheme.bodySmall?.apply(color: Colors.grey),
                    ),
                    value: state.appLockEnabled,
                    onChanged: (value) async {
                      if (value) {
                        final result = await _biometrics.authenticate(
                          reason: 'Verify your identity to enable app lock',
                        );
                        if (!mounted) return;
                        if (result == AuthResult.success) {
                          context.read<AppCubit>().updateAppLock(true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_biometrics.friendlyMessage(result))),
                          );
                        }
                      } else {
                        context.read<AppCubit>().updateAppLock(false);
                      }
                    },
                  ),
                ],

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
                    ConfirmModal.showConfirmDialog(
                        context, title: "Export JSON Backup?",
                        content: const Text("Export all data to a JSON backup file"),
                        onConfirm: () async {
                          Navigator.of(context).pop();
                          LoadingModal.showLoadingDialog(context, content: const Text("Exporting..."));
                          await export().then((value) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved to $value")));
                          }).catchError((err) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Export failed")));
                          }).whenComplete(() {
                            Navigator.of(context).pop();
                          });
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
                    ConfirmModal.showConfirmDialog(
                        context, title: "Export CSV?",
                        content: const Text("Export all transactions to a CSV spreadsheet"),
                        onConfirm: () async {
                          Navigator.of(context).pop();
                          LoadingModal.showLoadingDialog(context, content: const Text("Exporting CSV..."));
                          await exportCsv().then((value) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Saved to $value")));
                          }).catchError((err) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("CSV export failed")));
                          }).whenComplete(() {
                            Navigator.of(context).pop();
                          });
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
                    await FilePicker.platform.pickFiles(
                        dialogTitle: "Pick backup file",
                        allowMultiple: false,
                        allowCompression: false,
                        type: FileType.custom,
                        allowedExtensions: ["json"]
                    ).then((pick) {
                      if (pick == null || pick.files.isEmpty) {
                        return ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select file")));
                      }
                      PlatformFile file = pick.files.first;
                      ConfirmModal.showConfirmDialog(
                          context, title: "Import Backup?",
                          content: const Text("All existing data will be replaced with the backup."),
                          onConfirm: () async {
                            Navigator.of(context).pop();
                            LoadingModal.showLoadingDialog(context, content: const Text("Importing..."));
                            await import(file.path!).then((value) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Successfully imported")));
                              Navigator.of(context).pop();
                            }).catchError((err) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Import failed")));
                            });
                          },
                          onCancel: () => Navigator.of(context).pop()
                      );
                    }).catchError((err) {
                      return ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Import failed")));
                    });
                  },
                  leading: const CircleAvatar(child: Icon(Symbols.upload)),
                  title: Text('Import', style: theme.textTheme.bodyMedium?.merge(const TextStyle(fontWeight: FontWeight.w500, fontSize: 15))),
                  subtitle: Text("Restore from JSON backup", style: theme.textTheme.bodySmall?.apply(color: Colors.grey)),
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
