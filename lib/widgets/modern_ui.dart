import 'package:flutter/material.dart';

import '../app/app_theme.dart';

class ModernDrawerItem {
  const ModernDrawerItem({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.selected,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
}

class ModernAppShell extends StatelessWidget {
  const ModernAppShell({
    super.key,
    required this.title,
    required this.body,
    required this.drawerHeader,
    required this.menuItems,
    required this.onLogout,
    this.showAppBar = true,
  });

  final String title;
  final Widget body;
  final Widget drawerHeader;
  final List<ModernDrawerItem> menuItems;
  final VoidCallback onLogout;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTheme.surfaceBase,
      appBar: showAppBar
          ? AppBar(
              title: Text(title),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: AppTheme.accent.withValues(alpha: 0.1),
                ),
              ),
            )
          : null,
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              drawerHeader,
              const SizedBox(height: AppTheme.spacingSm),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: AppTheme.spacingXs,
                  ),
                  children: [
                    for (final item in menuItems)
                      ModernDrawerTile(
                        label: item.label,
                        icon: item.icon,
                        selected: item.selected,
                        onTap: item.onTap,
                      ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingXs,
                      ),
                      child: ModernDrawerTile(
                        label: 'Çıkış Yap',
                        icon: Icons.logout_rounded,
                        selected: false,
                        iconColor: AppTheme.error,
                        onTap: onLogout,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: ClipRect(
        child: ColoredBox(
          color: AppTheme.surfaceBase,
          child: SafeArea(
            top: false,
            left: false,
            right: false,
            child: body,
          ),
        ),
      ),
    );
  }
}

/// Shell içi sayfalar için üst güvenli alan — AppBar ile çakışmayı önler.
class ShellPageInset extends StatelessWidget {
  const ShellPageInset({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class PremiumAvatar extends StatelessWidget {
  const PremiumAvatar({
    super.key,
    required this.name,
    this.image,
    this.radius = 28,
    this.selected = false,
  });

  final String name;
  final ImageProvider? image;
  final double radius;
  final bool selected;

  static String initialsFrom(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    final list = parts.toList();
    if (list.isEmpty) return '?';
    if (list.length == 1) {
      return list.first.substring(0, 1).toUpperCase();
    }
    return '${list.first.substring(0, 1)}${list[1].substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? AppTheme.accent
              : AppTheme.accent.withValues(alpha: 0.2),
          width: selected ? 2.5 : 1.5,
        ),
        boxShadow: AppTheme.softShadow(
          opacity: selected ? 0.3 : 0.15,
          blur: selected ? 18 : 12,
        ),
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppTheme.surfaceOverlay,
        backgroundImage: image,
        child: image == null
            ? Text(
                initialsFrom(name),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: radius * 0.55,
                  color: AppTheme.bronze,
                ),
              )
            : null,
      ),
    );
  }
}

class SelectionCapsule extends StatelessWidget {
  const SelectionCapsule({
    super.key,
    required this.label,
    this.sublabel,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final String? sublabel;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppTheme.spacingSm),
      child: Material(
        color: selected
            ? AppTheme.accent.withValues(alpha: 0.2)
            : AppTheme.surfaceOverlay.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: selected
                    ? AppTheme.accent.withValues(alpha: 0.6)
                    : AppTheme.accent.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected ? AppTheme.accent : AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (sublabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sublabel!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: selected
                              ? AppTheme.bronze
                              : AppTheme.textMuted,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModernDrawerTile extends StatelessWidget {
  const ModernDrawerTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.selected,
    this.iconColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? (selected ? AppTheme.accent : AppTheme.textSecondary);
    final bg = selected
        ? AppTheme.accent.withValues(alpha: 0.14)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
                        ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModernAuthScaffold extends StatelessWidget {
  const ModernAuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.leading,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.gradientBackground(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (leading != null) ...[
                  Align(alignment: Alignment.centerLeft, child: leading!),
                  const SizedBox(height: AppTheme.spacingMd),
                ],
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: AppTheme.glassCard(),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ModernPageHeader extends StatelessWidget {
  const ModernPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingSm,
        AppTheme.spacingMd,
        AppTheme.spacingSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class ModernEmptyState extends StatelessWidget {
  const ModernEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: AppTheme.glassCard(tint: AppTheme.surfaceOverlay),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.accent, size: 28),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (action != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            action!,
          ],
        ],
      ),
    );
  }
}

class ModernListCard extends StatelessWidget {
  const ModernListCard({
    super.key,
    required this.child,
    this.onTap,
    this.leading,
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Widget? leading;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppTheme.spacingSm),
          ],
          Expanded(child: child),
        ],
      ),
    );

    return Padding(
      padding: margin ?? const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Material(
        color: AppTheme.surfaceRaised.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

class ModernIconBadge extends StatelessWidget {
  const ModernIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}
