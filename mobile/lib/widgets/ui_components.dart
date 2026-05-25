import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// MessageBanner — unified error / success / info banners
// ---------------------------------------------------------------------------

class MessageBanner extends StatelessWidget {
  final String message;
  final MessageType type;
  final VoidCallback? onDismiss;

  const MessageBanner({
    super.key,
    required this.message,
    this.type = MessageType.error,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final config = _config(context);
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.borderColor, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(config.icon, color: config.color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: config.color, fontSize: 13, fontWeight: FontWeight.w500, height: 1.4),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, color: config.color, size: 18),
            ),
        ],
      ),
    );
  }

  _BannerConfig _config(BuildContext context) {
    final isDark = context.isDarkMode;
    switch (type) {
      case MessageType.error:
        return _BannerConfig(
          color: isDark ? const Color(0xFFFCA5A5) : AppColors.error,
          bg: isDark ? const Color(0xFF450A0A) : AppColors.errorSurface,
          borderColor: (isDark ? const Color(0xFFFCA5A5) : AppColors.error).withValues(alpha: 0.2),
          icon: Icons.error_outline_rounded,
        );
      case MessageType.success:
        return _BannerConfig(
          color: AppColors.secondary,
          bg: isDark ? const Color(0xFF064E3B) : AppColors.secondarySurface,
          borderColor: AppColors.secondary.withValues(alpha: 0.2),
          icon: Icons.check_circle_outline_rounded,
        );
      case MessageType.info:
        return _BannerConfig(
          color: isDark ? AppColors.primaryLight : AppColors.info,
          bg: isDark ? const Color(0xFF1E3A5F) : AppColors.primarySurface,
          borderColor: (isDark ? AppColors.primaryLight : AppColors.info).withValues(alpha: 0.2),
          icon: Icons.info_outline_rounded,
        );
      case MessageType.warning:
        return _BannerConfig(
          color: AppColors.warning,
          bg: isDark ? const Color(0xFF422006) : AppColors.warningSurface,
          borderColor: AppColors.warning.withValues(alpha: 0.2),
          icon: Icons.warning_amber_rounded,
        );
    }
  }
}

enum MessageType { error, success, info, warning }

class _BannerConfig {
  final Color color;
  final Color bg;
  final Color borderColor;
  final IconData icon;
  const _BannerConfig({required this.color, required this.bg, required this.borderColor, required this.icon});
}

// ---------------------------------------------------------------------------
// StatusBadge — consistent status chips
// ---------------------------------------------------------------------------

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.fromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const StatusBadge(label: 'Confirmed', color: AppColors.primary, icon: Icons.check_circle_outline);
      case 'completed':
        return const StatusBadge(label: 'Completed', color: AppColors.secondary, icon: Icons.task_alt);
      case 'cancelled':
        return const StatusBadge(label: 'Cancelled', color: AppColors.error, icon: Icons.cancel_outlined);
      case 'pending':
        return const StatusBadge(label: 'Awaiting Confirmation', color: AppColors.warning, icon: Icons.hourglass_top_rounded);
      case 'approved':
        return const StatusBadge(label: 'Approved', color: AppColors.secondary, icon: Icons.verified);
      case 'rejected':
        return const StatusBadge(label: 'Rejected', color: AppColors.error, icon: Icons.block);
      case 'verified':
        return const StatusBadge(label: 'Verified', color: AppColors.verified, icon: Icons.verified_user);
      case 'paid':
        return const StatusBadge(label: 'Paid', color: AppColors.secondary, icon: Icons.check_circle);
      case 'failed':
        return const StatusBadge(label: 'Failed', color: AppColors.error, icon: Icons.error_outline);
      case 'inactive':
        return const StatusBadge(label: 'Inactive', color: AppColors.textTertiary, icon: Icons.block);
      default:
        return StatusBadge(label: status, color: AppColors.textTertiary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EmptyStateWidget — consistent empty states
// ---------------------------------------------------------------------------

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.primarySurfaceColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 40, color: scheme.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: scheme.onSurface),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(minimumSize: const Size(160, 44)),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SectionHeader — consistent section titles with optional action
// ---------------------------------------------------------------------------

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!, style: const TextStyle(fontSize: 13)),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// InfoCard — consistent information display card
// ---------------------------------------------------------------------------

class InfoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const InfoCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
        boxShadow: context.isDarkMode ? AppShadows.darkSm : AppShadows.sm,
      ),
      child: child,
    );
    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

// ---------------------------------------------------------------------------
// TrustBanner — small trust/info banners
// ---------------------------------------------------------------------------

class TrustBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const TrustBanner({
    super.key,
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.textTertiaryColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: c, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// LoadingButton — elevated button with loading state
// ---------------------------------------------------------------------------

class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: backgroundColor != null
          ? ElevatedButton.styleFrom(backgroundColor: backgroundColor, foregroundColor: foregroundColor ?? Colors.white)
          : null,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
            )
          : icon != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                    Text(label),
                  ],
                )
              : Text(label),
    );
  }
}
