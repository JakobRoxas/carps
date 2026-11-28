import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/carps_icons.dart';

import '../../controllers/app_controller.dart';
import '../../models/carps_models.dart';
import '../theme/carps_colors.dart';
import '../theme/carps_theme.dart';

// -----------------------------------------------------------------------------
// Brand
// -----------------------------------------------------------------------------

class CarpsWordmark extends StatelessWidget {
  const CarpsWordmark({super.key, this.size = 24, this.onInverse = false});
  final double size;
  final bool onInverse;

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    return Semantics(
      label: 'CARPS',
      header: true,
      child: ExcludeSemantics(
        child: Text(
          'CARPS',
          style: TextStyle(
            fontFamily: 'OtomanopeeOne',
            fontSize: size,
            height: 1.0,
            letterSpacing: 0.5,
            color: onInverse ? c.accentOnInverse : c.accentFill,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Avatars
// -----------------------------------------------------------------------------

class CarpsAvatar extends StatelessWidget {
  const CarpsAvatar({super.key, required this.user, this.size = 40, this.ring});
  final UserProfile? user;
  final double size;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    final u = user;
    final initials = (u == null || u.displayName.isEmpty)
        ? '?'
        : u.displayName
            .split(' ')
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0].toUpperCase())
            .join();
    Widget child;
    if (u?.avatarAsset != null) {
      child = Image.asset(u!.avatarAsset!,
          width: size, height: size, fit: BoxFit.cover);
    } else {
      child = Container(
        width: size,
        height: size,
        color: c.muted,
        alignment: Alignment.center,
        child: Text(initials,
            style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w600,
                color: c.textPrimary)),
      );
    }
    return Semantics(
      label: u == null ? 'Avatar' : '${u.displayName} avatar',
      image: true,
      child: Container(
        decoration: ring == null
            ? null
            : BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ring!, width: 2)),
        child: ClipOval(child: child),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Buttons
// -----------------------------------------------------------------------------

enum CarpsButtonKind { primary, inverse, secondary, muted, danger }

class CarpsButton extends StatelessWidget {
  const CarpsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = CarpsButtonKind.primary,
    this.icon,
    this.trailingArrow = false,
    this.loading = false,
    this.height = 52,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final CarpsButtonKind kind;
  final IconData? icon;
  final bool trailingArrow;
  final bool loading;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    final enabled = onPressed != null && !loading;
    late Color bg;
    late Color fg;
    BorderSide side = BorderSide.none;
    switch (kind) {
      case CarpsButtonKind.primary:
        bg = c.accentFill;
        fg = c.onAccent;
      case CarpsButtonKind.inverse:
        bg = c.selectFill;
        fg = c.onSelect;
      case CarpsButtonKind.secondary:
        bg = Colors.transparent;
        fg = c.textPrimary;
        side = BorderSide(color: c.borderStrong, width: 1.5);
      case CarpsButtonKind.muted:
        bg = c.muted;
        fg = c.textPrimary;
      case CarpsButtonKind.danger:
        bg = c.error;
        fg = c.onError;
    }
    if (!enabled && !loading) {
      bg = kind == CarpsButtonKind.secondary ? Colors.transparent : c.muted;
      fg = c.textDisabled;
    }
    final content = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: carpsBodyFont,
                        fontSize: height >= 52 ? 16 : 14,
                        fontWeight: FontWeight.w700,
                        color: fg)),
              ),
              if (trailingArrow) ...[
                const SizedBox(width: 8),
                Icon(CarpsIcons.arrowRightBold, size: 16, color: fg),
              ],
            ],
          );
    final button = TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg,
        minimumSize: Size(expand ? double.infinity : 0, height),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: StadiumBorder(side: side),
      ),
      child: content,
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 44,
    this.background,
    this.foreground,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background ?? c.muted,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: 20, color: foreground ?? c.textPrimary),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Segmented control
// -----------------------------------------------------------------------------

class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.badges = const {},
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final Map<int, String> badges;

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: c.muted, borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                selected: i == selected,
                button: true,
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected ? c.selectFill : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: FocusableActionDetector(
                      mouseCursor: SystemMouseCursors.click,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(labels[i],
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: i == selected
                                        ? c.onSelect
                                        : c.textSecondary)),
                          ),
                          if (badges[i] != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                  color: i == selected
                                      ? c.accentFill
                                      : c.borderSubtle,
                                  borderRadius: BorderRadius.circular(999)),
                              child: Text(badges[i]!,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: i == selected
                                          ? c.onAccent
                                          : c.textSecondary)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Chips
// -----------------------------------------------------------------------------

class SelectChip extends StatelessWidget {
  const SelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.selectFill : c.muted,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon ??
                      (selected
                          ? CarpsIcons.checkCircleFill
                          : CarpsIcons.plus),
                  size: 14,
                  color: selected ? c.accentOnInverse : c.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: selected ? c.onSelect : c.textPrimary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum StatusKind {
  invited,
  pending,
  approved,
  declined,
  withdrawn,
  checkedIn,
  noShow,
  cancelled,
  ended,
  private,
  public,
  live,
  booked,
}

/// Status chip: always an icon AND a text label (never color alone).
class StatusChip extends StatelessWidget {
  const StatusChip(this.kind, {super.key, this.label});
  final StatusKind kind;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    late IconData icon;
    late String text;
    Color bg = c.muted;
    Color fg = c.textSecondary;
    var strike = false;
    switch (kind) {
      case StatusKind.invited:
        icon = CarpsIcons.envelopeSimple;
        text = 'Invited';
        bg = c.accentTint;
        fg = c.accentText;
      case StatusKind.pending:
        icon = CarpsIcons.hourglassMedium;
        text = 'Pending';
      case StatusKind.approved:
        icon = CarpsIcons.checkCircleFill;
        text = 'Approved';
        fg = c.success;
      case StatusKind.declined:
        icon = CarpsIcons.xCircle;
        text = 'Declined';
        fg = c.error;
      case StatusKind.withdrawn:
        icon = CarpsIcons.arrowUUpLeft;
        text = 'Withdrawn';
      case StatusKind.checkedIn:
        icon = CarpsIcons.sealCheckFill;
        text = 'Checked in';
        bg = c.accentFill;
        fg = c.onAccent;
      case StatusKind.noShow:
        icon = CarpsIcons.minusCircle;
        text = 'No-show';
      case StatusKind.cancelled:
        icon = CarpsIcons.prohibit;
        text = 'Cancelled';
        fg = c.error;
        strike = true;
      case StatusKind.ended:
        icon = CarpsIcons.flagCheckered;
        text = 'Ended';
      case StatusKind.private:
        icon = CarpsIcons.lockSimple;
        text = 'Private';
        bg = c.inverse;
        fg = c.onInverse;
      case StatusKind.public:
        icon = CarpsIcons.globeSimple;
        text = 'Public';
      case StatusKind.live:
        icon = CarpsIcons.circleFill;
        text = 'Live now';
        bg = c.accentTint;
        fg = c.accentText;
      case StatusKind.booked:
        icon = CarpsIcons.ticket;
        text = 'Booked';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(label ?? text,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  decoration: strike ? TextDecoration.lineThrough : null,
                  decorationColor: fg)),
        ],
      ),
    );
  }
}

StatusKind statusFor(RegistrationStatus s) => switch (s) {
      RegistrationStatus.pending => StatusKind.pending,
      RegistrationStatus.approved => StatusKind.approved,
      RegistrationStatus.declined => StatusKind.declined,
      RegistrationStatus.withdrawn => StatusKind.withdrawn,
    };

/// Small pill used to mark anything simulated (email, contacts, camera…).
class SimulatedTag extends StatelessWidget {
  const SimulatedTag({super.key, this.text = 'Simulated'});
  final String text;
  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          border: Border.all(color: c.borderStrong),
          borderRadius: BorderRadius.circular(999)),
      child: Text(text.toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
              color: c.textSecondary)),
    );
  }
}

class TintPill extends StatelessWidget {
  const TintPill(this.text, {super.key, this.icon});
  final String text;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
          color: c.accentTint, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: c.accentFill),
          const SizedBox(width: 4),
        ],
        Text(text.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w600,
                color: c.accentFill)),
      ]),
    );
  }
}

// -----------------------------------------------------------------------------
// Surfaces
// -----------------------------------------------------------------------------

/// The dark sheet under the curved seam (island rule 1: dark tokens inside).
class DarkSheet extends StatelessWidget {
  const DarkSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 28, 16, 32),
    this.fill = false,
    this.roundBottom = false,
  });
  final Widget child;
  final EdgeInsets padding;
  final bool fill;
  final bool roundBottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: fill
          ? BoxConstraints(minHeight: MediaQuery.sizeOf(context).height * 0.6)
          : null,
      decoration: BoxDecoration(
        color: CarpsColors.light.inverse,
        borderRadius: roundBottom
            ? BorderRadius.circular(36)
            : const BorderRadius.vertical(top: Radius.circular(36)),
      ),
      padding: padding,
      child: Theme(
        data: carpsDarkTheme.copyWith(
            scaffoldBackgroundColor: CarpsColors.light.inverse),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: CarpsColors.dark.textPrimary),
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    );
  }
}

/// The single bright card on a dark sheet (island rule 2: light tokens).
class HighlightCard extends StatelessWidget {
  const HighlightCard({super.key, required this.child, this.padding = 20});
  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: CarpsColors.light.highlight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Theme(
        data: carpsLightTheme,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: CarpsColors.light.textPrimary),
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: color ?? (isDark ? c.inverseRaised : c.canvas),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
              child: Text(title,
                  style: Theme.of(context).textTheme.titleLarge)),
          ?trailing,
        ],
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 6),
      child: Row(children: [
        Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.carps.textPrimary)),
        ),
        ?trailing,
      ]),
    );
  }
}

class CaptionLabel extends StatelessWidget {
  const CaptionLabel(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: TextStyle(
          fontSize: 11,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
          color: color ?? context.carps.textSecondary));
}

// -----------------------------------------------------------------------------
// States: loading, empty, error
// -----------------------------------------------------------------------------

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Opacity(
            opacity: 0.85,
            child: Image.asset('assets/images/carp_orange.png',
                width: 72, height: 72),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.carps.textSecondary)),
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            CarpsButton(
                label: actionLabel!,
                onPressed: onAction,
                kind: CarpsButtonKind.inverse,
                height: 44,
                expand: false),
          ],
        ],
      ),
    );
  }
}

/// Visually distinct from [EmptyState]: warning icon + Try again.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Icon(CarpsIcons.warningCircle, size: 56, color: c.error),
          const SizedBox(height: 16),
          Text('Something went wrong',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: c.textSecondary)),
          const SizedBox(height: 20),
          CarpsButton(
              label: 'Try again',
              icon: CarpsIcons.arrowClockwise,
              onPressed: onRetry,
              kind: CarpsButtonKind.secondary,
              height: 44,
              expand: false),
        ],
      ),
    );
  }
}

class LoadingBlock extends StatelessWidget {
  const LoadingBlock({super.key, this.lines = 3});
  final int lines;
  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    return Semantics(
      label: 'Loading',
      child: Column(
        children: [
          for (var i = 0; i < lines; i++)
            Container(
              height: 72,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: c.muted, borderRadius: BorderRadius.circular(16)),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Headers
// -----------------------------------------------------------------------------

/// Shell top bar: CARPS wordmark LEFT, notification bell + avatar RIGHT.
class CarpsTopBar extends StatelessWidget {
  const CarpsTopBar({super.key, this.showWordmark = true});
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    final me = app.me;
    final unread = me == null ? 0 : app.notifications.unreadCount(me.id);
    final c = context.carps;
    return Container(
      height: 64,
      color: c.canvas.withValues(alpha: 0.9),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // On wide screens the navigation rail carries the wordmark.
          if (showWordmark && MediaQuery.sizeOf(context).width < 600)
            const CarpsWordmark(size: 22),
          const Spacer(),
          Semantics(
            label: unread > 0
                ? 'Notifications, $unread unread'
                : 'Notifications',
            button: true,
            child: IconButton(
              tooltip: 'Notifications',
              onPressed: () => context.push('/notifications'),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(CarpsIcons.bell,
                      size: 26, color: c.textPrimary),
                  if (unread > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                            color: c.accentFill,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.canvas, width: 1.5)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          if (me != null)
            Tooltip(
              message: 'Your profile',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.go('/profile'),
                child: CarpsAvatar(user: me, size: 36),
              ),
            ),
        ],
      ),
    );
  }
}

/// Secondary-screen header: back, title, optional trailing action.
class BackHeader extends StatelessWidget {
  const BackHeader({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    return Container(
      height: 64,
      color: c.canvas.withValues(alpha: 0.9),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            icon: Icon(CarpsIcons.arrowLeft, color: c.textPrimary),
            onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(title,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          ?trailing,
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// Copyright line for app footers; adapts to the surrounding surface.
class CarpsCopyright extends StatelessWidget {
  const CarpsCopyright({super.key});

  @override
  Widget build(BuildContext context) => Text(
        '© Carps. Co. All Rights Reserved.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.carps.textSecondary,
            ),
      );
}

/// Standard scrollable secondary page with a [BackHeader] and a max width.
class CarpsPage extends StatelessWidget {
  const CarpsPage({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
    this.bottomBar,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 32),
    this.maxWidth = 720,
  });
  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final Widget? bottomBar;
  final EdgeInsets padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackHeader(title: title, trailing: trailing),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Padding(
                        padding: padding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: children,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: bottomBar == null ? null : BottomActionBar(child: bottomBar!),
    );
  }
}

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final c = context.carps;
    return Container(
      decoration: BoxDecoration(
        color: c.canvas,
        border: Border(top: BorderSide(color: c.borderSubtle)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      // heightFactor 1: a plain Center would expand to the whole screen
      // and push floating SnackBars off-screen.
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720), child: child),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Feedback helpers
// -----------------------------------------------------------------------------

void showCarpsSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.hideCurrentSnackBar();
  messenger?.showSnackBar(SnackBar(
    content: Row(children: [
      Icon(
          error
              ? CarpsIcons.warningCircle
              : CarpsIcons.checkCircle,
          color: error ? const Color(0xFFFF6B60) : const Color(0xFF3DD47A),
          size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(message)),
    ]),
  ));
}

/// Runs a rule-checked action and turns [RuleViolation]s into a snackbar.
bool runAction(BuildContext context, void Function() action, {String? success}) {
  try {
    action();
    if (success != null) showCarpsSnack(context, success);
    return true;
  } on RuleViolation catch (e) {
    showCarpsSnack(context, e.message, error: true);
    return false;
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: Theme.of(ctx).textTheme.titleLarge),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(children: [
          Expanded(
            child: CarpsButton(
                label: 'Cancel',
                height: 44,
                kind: CarpsButtonKind.secondary,
                onPressed: () => Navigator.pop(ctx, false)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CarpsButton(
                label: confirmLabel,
                height: 44,
                kind: destructive
                    ? CarpsButtonKind.danger
                    : CarpsButtonKind.primary,
                onPressed: () => Navigator.pop(ctx, true)),
          ),
        ]),
      ],
    ),
  );
  return result ?? false;
}
