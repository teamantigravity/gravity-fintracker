import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:fintracker/services/haptic_service.dart';
import 'prism_tokens.dart';

/// A living, glass-aware card with subtle depth, gradient, and motion.
class PrismCard extends StatefulWidget {
  final Widget child;
  final bool isGlass;
  final double? blurSigma;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderWidth;
  final bool hasShadow;
  final Color? shadowColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final bool scaleOnTap;

  const PrismCard({
    super.key,
    required this.child,
    this.isGlass = false,
    this.blurSigma,
    this.backgroundColor,
    this.gradient,
    this.borderColor,
    this.borderWidth = 1,
    this.hasShadow = true,
    this.shadowColor,
    this.borderRadius = PrismTokens.radiusLg,
    this.padding = const EdgeInsets.all(PrismTokens.spaceMd),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.scaleOnTap = true,
  });

  @override
  State<PrismCard> createState() => _PrismCardState();
}

class _PrismCardState extends State<PrismCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      color: widget.gradient == null
          ? (widget.backgroundColor ?? colorScheme.surfaceContainerHighest.withValues(alpha: PrismTokens.glassOpacity))
          : null,
      gradient: widget.gradient,
      border: widget.borderColor != null
          ? Border.all(color: widget.borderColor!, width: widget.borderWidth)
          : null,
      boxShadow: widget.hasShadow
          ? [
              BoxShadow(
                color: (widget.shadowColor ?? colorScheme.shadow).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    );

    Widget card = Container(
      margin: widget.margin,
      padding: widget.padding,
      decoration: decoration,
      child: widget.child,
    );

    card = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: widget.isGlass
          ? BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.blurSigma ?? PrismTokens.blurSigma,
                sigmaY: widget.blurSigma ?? PrismTokens.blurSigma,
              ),
              child: card,
            )
          : card,
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTap: () {
        HapticService.light();
        widget.onTap!();
      },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: widget.scaleOnTap && _pressed ? 0.97 : 1.0,
        duration: PrismTokens.durationFast,
        curve: PrismCurves.snap,
        child: card,
      ),
    );
  }
}

/// A crisp, modern button with tactile feedback and a premium feel.
class PrismButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String? label;
  final Widget? child;
  final IconData? icon;
  final bool isLoading;
  final bool isStretched;
  final PrismButtonVariant variant;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const PrismButton({
    super.key,
    this.onPressed,
    this.label,
    this.child,
    this.icon,
    this.isLoading = false,
    this.isStretched = true,
    this.variant = PrismButtonVariant.primary,
    this.height,
    this.padding,
    this.borderRadius,
  });

  @override
  State<PrismButton> createState() => _PrismButtonState();
}

enum PrismButtonVariant { primary, secondary, outline, ghost }

class _PrismButtonState extends State<PrismButton> {
  bool _pressed = false;

  Color _foreground(ColorScheme colorScheme) {
    switch (widget.variant) {
      case PrismButtonVariant.primary:
        return colorScheme.onPrimary;
      case PrismButtonVariant.secondary:
        return colorScheme.onPrimaryContainer;
      case PrismButtonVariant.outline:
      case PrismButtonVariant.ghost:
        return colorScheme.primary;
    }
  }

  BoxDecoration _decoration(ColorScheme colorScheme) {
    final radius = BorderRadius.circular(widget.borderRadius ?? PrismTokens.buttonRadius);
    switch (widget.variant) {
      case PrismButtonVariant.primary:
        return BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.85)],
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        );
      case PrismButtonVariant.secondary:
        return BoxDecoration(
          borderRadius: radius,
          color: colorScheme.primaryContainer.withValues(alpha: 0.7),
        );
      case PrismButtonVariant.outline:
        return BoxDecoration(
          borderRadius: radius,
          color: Colors.transparent,
          border: Border.all(color: colorScheme.primary, width: 1.5),
        );
      case PrismButtonVariant.ghost:
        return BoxDecoration(
          borderRadius: radius,
          color: Colors.transparent,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = _foreground(colorScheme);
    final canTap = widget.onPressed != null && !widget.isLoading;

    final content = widget.isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              ),
              if (widget.label != null) ...[
                const SizedBox(width: 10),
                Text(widget.label!, style: TextStyle(color: foreground, fontWeight: FontWeight.w600, fontSize: 16)),
              ],
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: foreground, size: 20),
                const SizedBox(width: 8),
              ],
              if (widget.label != null)
                Text(widget.label!, style: TextStyle(color: foreground, fontWeight: FontWeight.w600, fontSize: 16)),
              if (widget.child != null) widget.child!,
            ],
          );

    return GestureDetector(
      onTap: canTap ? () {
        HapticService.light();
        widget.onPressed!();
      } : null,
      onTapDown: canTap ? (_) => setState(() => _pressed = true) : null,
      onTapUp: canTap ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: canTap ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: PrismTokens.durationFast,
        curve: PrismCurves.snap,
        child: Container(
          height: widget.height ?? PrismTokens.buttonHeight,
          width: widget.isStretched ? double.infinity : null,
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: PrismTokens.spaceLg),
          alignment: Alignment.center,
          decoration: _decoration(colorScheme),
          child: content,
        ),
      ),
    );
  }
}

/// A clean, premium avatar with color-matched background.
class PrismAvatar extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double iconSize;
  final BoxShape shape;
  final double? borderRadius;

  const PrismAvatar({
    super.key,
    this.icon,
    this.child,
    this.color,
    this.backgroundColor,
    this.size = PrismTokens.avatarSize,
    this.iconSize = PrismTokens.avatarIconSize,
    this.shape = BoxShape.circle,
    this.borderRadius,
  }) : assert(icon != null || child != null, 'Provide either an icon or a child');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final c = color ?? colorScheme.primary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? c.withValues(alpha: 0.12),
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(borderRadius ?? PrismTokens.radiusSm) : null,
      ),
      child: child ?? Icon(icon, color: c, size: iconSize),
    );
  }
}

/// A premium list row with tap feedback and support for icons, avatars, and trailing controls.
class PrismListTile extends StatefulWidget {
  final Widget? leading;
  final IconData? icon;
  final Color? iconColor;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const PrismListTile({
    super.key,
    this.leading,
    this.icon,
    this.iconColor,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: PrismTokens.spaceMd, vertical: PrismTokens.spaceSm + 4),
  });

  @override
  State<PrismListTile> createState() => _PrismListTileState();
}

class _PrismListTileState extends State<PrismListTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final leading = widget.leading ??
        (widget.icon != null
            ? PrismAvatar(
                icon: widget.icon,
                color: widget.iconColor,
                size: PrismTokens.avatarSize,
                iconSize: PrismTokens.avatarIconSize,
              )
            : null);

    final tile = AnimatedContainer(
      duration: PrismTokens.durationFast,
      color: _pressed ? colorScheme.primary.withValues(alpha: 0.06) : Colors.transparent,
      padding: widget.padding,
      child: Row(
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.title != null) widget.title!,
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 2),
                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.bodySmall!,
                    child: widget.subtitle!,
                  ),
                ],
              ],
            ),
          ),
          if (widget.trailing != null) ...[
            const SizedBox(width: 8),
            widget.trailing!,
          ],
        ],
      ),
    );

    if (widget.onTap == null) return tile;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticService.light();
        widget.onTap!();
      },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: PrismTokens.durationFast,
        curve: PrismCurves.snap,
        child: tile,
      ),
    );
  }
}

/// A section with a title and a grouped card container.
class PrismSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry margin;
  final bool showDividers;

  const PrismSection({
    super.key,
    this.title,
    required this.children,
    this.margin = const EdgeInsets.only(bottom: PrismTokens.spaceMd),
    this.showDividers = true,
  });

  List<Widget> _buildChildren(BuildContext context) {
    if (!showDividers || children.length <= 1) return children;
    final divider = Divider(height: 0, thickness: 0.5, color: Theme.of(context).dividerColor);
    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) result.add(divider);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: PrismTokens.spaceSm),
              child: Text(
                title!,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          PrismCard(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildChildren(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small, colorful pill used for labels, tags, and counts.
class PrismChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final bool isSmall;

  const PrismChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.onTap,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final c = color ?? colorScheme.primary;
    return GestureDetector(
      onTap: onTap != null
          ? () {
              HapticService.light();
              onTap!();
            }
          : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 10, vertical: isSmall ? 3 : 4),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: isSmall ? 12 : 14, color: c),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: c,
                fontSize: isSmall ? 10 : 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating, premium bottom navigation with tactile selection.
class PrismBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTap;
  final List<PrismBottomNavItem> items;

  const PrismBottomNav({
    super.key,
    required this.selectedIndex,
    required this.items,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BottomAppBar(
      elevation: 0,
      color: Colors.transparent,
      padding: EdgeInsets.zero,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(PrismTokens.radiusLg),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(PrismTokens.radiusLg),
            child: Row(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Expanded(
                  child: _PrismBottomNavItem(
                    icon: item.icon,
                    label: item.label,
                    isSelected: selectedIndex == index,
                    onTap: onTap != null ? () => onTap!(index) : null,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class PrismBottomNavItem {
  final IconData icon;
  final String label;
  const PrismBottomNavItem({required this.icon, required this.label});
}

class _PrismBottomNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PrismBottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<_PrismBottomNavItem> createState() => _PrismBottomNavItemState();
}

class _PrismBottomNavItemState extends State<_PrismBottomNavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = widget.isSelected ? colorScheme.onPrimary : colorScheme.onSurface.withValues(alpha: 0.55);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticService.selection();
        widget.onTap?.call();
      },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.85 : 1.0,
        duration: PrismTokens.durationFast,
        curve: PrismCurves.bounce,
        child: AnimatedContainer(
          duration: PrismTokens.durationFast,
          curve: PrismCurves.snap,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: widget.isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(PrismTokens.radiusMd),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: color, size: widget.isSelected ? 24 : 22),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: PrismTokens.durationFast,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
                child: Text(widget.label, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A soothing empty state for when there is nothing to show.
class PrismEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PrismEmptyState({
    super.key,
    this.icon = Symbols.receipt_long,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(PrismTokens.spaceLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.12)),
          const SizedBox(height: PrismTokens.spaceMd),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.35),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: PrismTokens.spaceSm),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.25),
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: PrismTokens.spaceMd),
            PrismButton(
              variant: PrismButtonVariant.secondary,
              label: actionLabel,
              onPressed: onAction,
              isStretched: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// A smooth, premium page route for navigation.
class PrismPageRoute<T> extends PageRouteBuilder<T> {
  final WidgetBuilder builder;

  PrismPageRoute({
    required this.builder,
    super.settings,
  }) : super(
          transitionDuration: PrismTokens.durationMedium,
          reverseTransitionDuration: PrismTokens.durationFast,
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fade = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: PrismCurves.smooth),
            );
            final slide = Tween<Offset>(begin: const Offset(0.03, 0.06), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: PrismCurves.smooth),
            );
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: child,
              ),
            );
          },
        );
}
