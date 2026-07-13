import 'package:fintracker/model/account.model.dart';
import 'package:fintracker/widgets/currency.dart';
import 'package:fintracker/widgets/dialog/account_form.dialog.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class AccountsSlider extends StatefulWidget {
  final List<Account> accounts;
  const AccountsSlider({super.key, required this.accounts});
  @override
  State<StatefulWidget> createState() => _AccountSlider();
}

class _AccountSlider extends State<AccountsSlider> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _selected = 0;

  // +1 slot for the trailing "Add account" card.
  int get _pageCount => widget.accounts.length + 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 176,
          child: PageView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _pageCount,
            controller: _pageController,
            padEnds: false,
            onPageChanged: (int index) => setState(() => _selected = index),
            itemBuilder: (BuildContext builder, int index) {
              if (index == widget.accounts.length) {
                return _AddAccountCard(onTap: () {
                  showDialog(context: context, builder: (_) => const AccountForm());
                });
              }
              return _AccountCard(account: widget.accounts[index]);
            },
          )
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pageCount, (index) {
              final isAccount = index < widget.accounts.length;
              final dotColor = isAccount ? widget.accounts[index].color : colorScheme.outlineVariant;
              return AnimatedContainer(
                curve: Curves.ease,
                height: 6,
                duration: const Duration(milliseconds: 200),
                width: _selected == index ? 20 : 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: _selected == index ? dotColor : dotColor.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(60),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account account;
  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [account.color.withOpacity(0.85), account.color],
        ),
        boxShadow: [
          BoxShadow(
            color: account.color.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Subtle diagonal sheen for a premium "card material" feel.
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(account.icon, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              account.holderName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.65)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "BALANCE",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  CurrencyText(
                    account.balance ?? 0,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Symbols.arrow_downward, size: 13, color: Colors.white.withOpacity(0.85)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: CurrencyText(
                          account.income ?? 0,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(Symbols.arrow_upward, size: 13, color: Colors.white.withOpacity(0.85)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: CurrencyText(
                          account.expense ?? 0,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAccountCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddAccountCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.4),
                width: 1.2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Symbols.add, color: colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add Account",
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
