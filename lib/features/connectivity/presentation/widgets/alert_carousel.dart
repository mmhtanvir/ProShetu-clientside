import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../coordination/domain/crisis_alert.dart';

/// Swipeable active-alert cards with page dots. Alerts are the one
/// place swiping stays enabled — quick triage matters here.
class AlertCarousel extends StatefulWidget {
  const AlertCarousel({required this.alerts, super.key});

  final List<CrisisAlert> alerts;

  @override
  State<AlertCarousel> createState() => _AlertCarouselState();
}

class _AlertCarouselState extends State<AlertCarousel> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          height: 132,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.alerts.length,
            itemBuilder: (BuildContext context, int i) {
              final CrisisAlert alert = widget.alerts[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.10),
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.danger, size: 20),
                        const Spacer(),
                        Text(
                          alert.ageLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(alert.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Expanded(
                      child: Text(
                        alert.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ListenableBuilder(
          listenable: _controller,
          builder: (BuildContext context, _) {
            final int page = _controller.hasClients
                ? (_controller.page ?? 0).round()
                : 0;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < widget.alerts.length; i++)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == page
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.outline,
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
