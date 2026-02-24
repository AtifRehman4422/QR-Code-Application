import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/qr_code_model.dart';
import '../utils/qr_scanner.dart';

class QrCard extends StatelessWidget {
  final QrCodeModel model;
  final String displayContent;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onToggleFavorite;
  final int? analyticsCount;
  final bool isDark;

  const QrCard({
    super.key,
    required this.model,
    required this.displayContent,
    this.onTap,
    this.onDelete,
    this.onShare,
    this.onToggleFavorite,
    this.analyticsCount,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = displayContent;
    final preview = content.length > 80 ? '${content.substring(0, 80)}...' : content;
    final typeLabel = getQrTypeDisplayName(model.type);
    final theme = Theme.of(context);

    Widget card = Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(6),
                child: QrImageView(
                  data: content,
                  version: QrVersions.auto,
                  backgroundColor: isDark ? Colors.transparent : Colors.white,
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  gapless: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            typeLabel,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (model.expiresAt != null &&
                            DateTime.now().isAfter(model.expiresAt!)) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_off_rounded, size: 16, color: theme.colorScheme.error),
                                const SizedBox(width: 4),
                                Text(
                                  'Expired',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if ((analyticsCount ?? 0) > 1) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bar_chart_rounded, size: 16, color: Colors.orange),
                                const SizedBox(width: 4),
                                Text(
                                  'Scans: ${analyticsCount!}',
                                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.orange),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      preview,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(model.timestamp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (onShare != null || onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
            ],
          ),
        ),
      ),
    );

    if (onDelete != null) {
      return Slidable(
        key: ValueKey(model.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: onToggleFavorite != null ? 0.5 : 0.25,
          children: [
            if (onToggleFavorite != null)
              SlidableAction(
                onPressed: (context) => onToggleFavorite!(),
                backgroundColor: model.isFavorite ? Colors.amber : theme.colorScheme.primary,
                foregroundColor: model.isFavorite ? Colors.black87 : theme.colorScheme.onPrimary,
                icon: model.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                label: model.isFavorite ? 'Unfavorite' : 'Favorite',
              ),
            SlidableAction(
              onPressed: (context) => onDelete!(),
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              icon: Icons.delete_outline,
              label: 'Delete',
            ),
          ],
        ),
        child: card,
      );
    }
    return card;
  }

  static String _formatDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(d.year, d.month, d.day);
    if (date == today) {
      return 'Today ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == yesterday) {
      return 'Yesterday';
    }
    return '${d.day}/${d.month}/${d.year}';
  }
}
