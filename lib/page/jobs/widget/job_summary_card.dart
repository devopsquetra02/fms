import 'package:flutter/material.dart';

/// A model representing a badge on the job summary card.
class JobCardBadge {
  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  const JobCardBadge({
    required this.label,
    this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  });
}

/// A card widget displaying a summary of a job.
class JobSummaryCard extends StatelessWidget {
  final String title;
  final String? customerName;
  final String? address;
  final String? dateLabel;
  final List<JobCardBadge> badges;
  final VoidCallback? onTap;
  final VoidCallback? onDetails;
  final String detailsLabel;
  final Color accentColor;
  final List<Color>? gradientColors;

  const JobSummaryCard({
    super.key,
    required this.title,
    this.customerName,
    this.address,
    this.dateLabel,
    this.badges = const [],
    this.onTap,
    this.onDetails,
    this.detailsLabel = 'Details',
    this.accentColor = const Color(0xFF1E58FF),
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final accent = gradientColors?.last ?? accentColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap ?? onDetails,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
            border: Border.all(color: accent.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (customerName != null && customerName!.isNotEmpty)
                _InfoRow(
                  icon: Icons.person_outline,
                  label: customerName!,
                  color: accent,
                ),
              if (dateLabel != null) ...[
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: dateLabel!,
                  color: accent,
                ),
              ],
              if (address != null && address!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: address!,
                  color: accent,
                  maxLines: 2,
                ),
              ],
              if (badges.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: badges
                      .map((badge) => _BadgeChip(badge: badge))
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onDetails ?? onTap,
                  // icon: Icon(Icons.arrow_forward_rounded,
                  //     size: 18, color: accent),
                  label: Text(
                    detailsLabel,
                    style: textTheme.labelLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    foregroundColor: accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    overlayColor: accent.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int maxLines;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.color,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: maxLines == 1
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final JobCardBadge badge;

  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: badge.backgroundColor,
        border: Border.all(
          color: (badge.borderColor ?? badge.foregroundColor).withValues(
            alpha: 0.2,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge.icon != null) ...[
              Icon(badge.icon, size: 16, color: badge.foregroundColor),
              const SizedBox(width: 6),
            ],
            Text(
              badge.label,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: badge.foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
