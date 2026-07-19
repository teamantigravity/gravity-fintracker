import 'package:fintracker/services/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:fintracker/theme/prism_colors.dart';
import 'package:fintracker/config/strings.dart';
import 'package:material_symbols_icons/symbols.dart';

class PrivacyDashboardScreen extends StatelessWidget {
  const PrivacyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final syncService = SyncService();

    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.privacyDashboard),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy score
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.15),
                    colorScheme.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    Symbols.verified_user,
                    size: 48,
                    color: colorScheme.primary,
                    fill: 1,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Strings.yourPrivacyScore,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Strings.s100,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Strings.privacyPromise,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text(
              Strings.privacyGuarantees,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            const _PrivacyItem(
              icon: Symbols.storage,
              title: 'Local-Only Storage',
              description: 'All data stored on your device using SQLite. Nothing in the cloud unless you opt in.',
              status: _PrivacyStatus.verified,
            ),
            const _PrivacyItem(
              icon: Symbols.analytics,
              title: 'Zero Analytics',
              description: 'No Firebase, no Crashlytics, no third-party tracking SDKs. Zero telemetry.',
              status: _PrivacyStatus.verified,
            ),
            const _PrivacyItem(
              icon: Symbols.wifi_off,
              title: 'No Network Requests',
              description: 'The app makes zero network calls in Free mode. Check your firewall.',
              status: _PrivacyStatus.verified,
            ),
            _PrivacyItem(
              icon: Symbols.lock,
              title: 'Quantum-Resistant Encryption',
              description: 'Sync uses ${Strings.encryptionStandard} with HKDF key derivation — quantum-hardened.',
              status: syncService.isEnabled
                  ? _PrivacyStatus.verified
                  : _PrivacyStatus.notApplicable,
              notApplicableReason: 'Sync not enabled',
            ),
            const _PrivacyItem(
              icon: Symbols.visibility_off,
              title: 'Zero-Knowledge Architecture',
              description: 'Even with sync, our servers store only ciphertext. We cannot read your data.',
              status: _PrivacyStatus.verified,
            ),
            const _PrivacyItem(
              icon: Symbols.security,
              title: 'Post-Quantum Key Stretching',
              description: '100K-round SHA-512 + HKDF-SHA512 key derivation resists both classical and quantum attacks.',
              status: _PrivacyStatus.verified,
            ),
            const _PrivacyItem(
              icon: Symbols.code,
              title: 'Open Source',
              description: 'Our code is open for audit. Trust, but verify.',
              status: _PrivacyStatus.verified,
            ),

            const SizedBox(height: 28),

            Text(
              Strings.dataSummary,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const _DataRow(
                    label: 'Data sent to servers',
                    value: '0 bytes',
                    icon: Symbols.cloud_off,
                    color: PrismColors.income,
                  ),
                  const Divider(height: 24),
                  const _DataRow(
                    label: 'Third-party trackers',
                    value: 'None',
                    icon: Symbols.block,
                    color: PrismColors.income,
                  ),
                  const Divider(height: 24),
                  const _DataRow(
                    label: 'Ads & profiling',
                    value: 'None',
                    icon: Symbols.do_not_disturb_on,
                    color: PrismColors.income,
                  ),
                  const Divider(height: 24),
                  _DataRow(
                    label: 'Encryption standard',
                    value: Strings.encryptionStandard,
                    icon: Symbols.enhanced_encryption,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Footer
            Center(
              child: Text(
                Strings.gravityFintrackerIsBuiltByPeople,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

enum _PrivacyStatus { verified, notApplicable }

class _PrivacyItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final _PrivacyStatus status;
  final String? notApplicableReason;

  const _PrivacyItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    this.notApplicableReason,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVerified = status == _PrivacyStatus.verified;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isVerified ? PrismColors.income : Colors.grey)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isVerified ? PrismColors.income : Colors.grey,
              size: 20,
              fill: 1,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      isVerified ? Symbols.check_circle : Symbols.remove_circle,
                      size: 16,
                      color: isVerified ? PrismColors.income : Colors.grey,
                      fill: 1,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    height: 1.3,
                  ),
                ),
                if (!isVerified && notApplicableReason != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      notApplicableReason ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DataRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color, fill: 1),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
      ],
    );
  }
}
