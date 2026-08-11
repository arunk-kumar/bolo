import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/bolo_colors.dart';
import '../../core/theme/bolo_dimens.dart';
import '../../core/theme/bolo_typography.dart';
import 'progress_service.dart';

/// Parent-only progress dashboard.
///
/// Gated by [ParentGate.ensure] at the call site — this screen itself
/// assumes it's already been unlocked. Reads from
/// [progressSummaryProvider] and shows a small set of stat tiles plus a
/// category breakdown.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(progressSummaryProvider);

    return Scaffold(
      backgroundColor: BoloColors.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: BoloColors.ink),
        title: Text('Progress', style: BoloTypography.screenTitle()),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: BoloLayout.contentMaxWidth),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                _headerLine(summary),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        emoji: '🗣️',
                        big: '${summary.wordsToday}',
                        label: 'WORDS TODAY',
                        accent: BoloColors.saffron,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        emoji: '📚',
                        big: '${summary.wordsTotal}',
                        label: 'ALL-TIME',
                        accent: BoloColors.sage,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatTile(
                  emoji: '🔥',
                  big: summary.streakDays == 0
                      ? '—'
                      : '${summary.streakDays} day${summary.streakDays == 1 ? "" : "s"}',
                  label: 'CURRENT STREAK',
                  accent: BoloColors.turmeric,
                  wide: true,
                ),
                const SizedBox(height: 24),
                Text('By category',
                    style: BoloTypography.subhead().copyWith(fontSize: 16)),
                const SizedBox(height: 8),
                _CategoryBreakdown(byCategory: summary.byCategory),
                const SizedBox(height: 24),
                _ResetButton(onReset: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => _ResetConfirmDialog(),
                  );
                  if (confirm == true) {
                    await ref.read(progressServiceProvider).reset();
                    ref.read(progressBumpProvider.notifier).state++;
                  }
                }),
                const SizedBox(height: 20),
                Text(
                  'A conversation guide, not a clinical assessment.\n'
                  'Every child grows at their own pace.',
                  textAlign: TextAlign.center,
                  style: BoloTypography.utilityLabel(color: BoloColors.ink3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerLine(ProgressSummary s) {
    final line = s.wordsTotal == 0
        ? "You're just getting started. Every voice makes ripples."
        : s.wordsToday > 0
            ? 'Great practice today. Keep it playful.'
            : 'A little practice today goes a long way.';
    return Text(line,
        style: BoloTypography.body(color: BoloColors.ink2)
            .copyWith(fontSize: 15, height: 1.4));
  }
}

// ── Stat tile ────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String emoji;
  final String big;
  final String label;
  final Color accent;
  final bool wide;

  const _StatTile({
    required this.emoji,
    required this.big,
    required this.label,
    required this.accent,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: 16, vertical: wide ? 18 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: BoloColors.paper3),
        borderRadius: BoloRadius.mdAll,
        boxShadow: BoloShadow.card,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(big,
                    style: BoloTypography.numericDisplay(
                            size: 26, color: BoloColors.ink)),
                Text(label,
                    style: BoloTypography.utilityLabel(color: accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category breakdown ───────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  final Map<String, int> byCategory;
  const _CategoryBreakdown({required this.byCategory});

  @override
  Widget build(BuildContext context) {
    if (byCategory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BoloColors.paper2,
          borderRadius: BoloRadius.mdAll,
          border: Border.all(color: BoloColors.paper3),
        ),
        child: Text(
          "Play a round to see which categories you've covered.",
          textAlign: TextAlign.center,
          style: BoloTypography.body(color: BoloColors.ink3),
        ),
      );
    }
    final total = byCategory.values.fold<int>(0, (a, b) => a + b);
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: entries.map((e) {
        final pct = total == 0 ? 0.0 : e.value / total;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  _prettyCategory(e.key),
                  style: BoloTypography.body(color: BoloColors.ink)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: pct,
                    backgroundColor: BoloColors.paper3,
                    valueColor: const AlwaysStoppedAnimation(BoloColors.saffron),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 34,
                child: Text(
                  '${e.value}',
                  textAlign: TextAlign.right,
                  style: BoloTypography.numericDisplay(
                      size: 14, color: BoloColors.ink),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _prettyCategory(String key) {
    switch (key) {
      case 'animals':  return 'Animals';
      case 'food':     return 'Food';
      case 'family':   return 'Family';
      case 'body':     return 'My body';
      case 'colours':  return 'Colours';
      case 'objects':  return 'Things';
      case 'vehicles': return 'Vehicles';
      case 'nature':   return 'Outside';
      default:         return key;
    }
  }
}

// ── Reset button + confirm dialog ────────────────────────────────

class _ResetButton extends StatelessWidget {
  final VoidCallback onReset;
  const _ResetButton({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onReset,
      style: OutlinedButton.styleFrom(
        foregroundColor: BoloColors.alert,
        side: BorderSide(color: BoloColors.alert.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: BoloRadius.pillAll),
      ),
      child: Text(
        'Reset progress',
        style: BoloTypography.utilityLabel(color: BoloColors.alert)
            .copyWith(fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ResetConfirmDialog extends StatelessWidget {
  const _ResetConfirmDialog();
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BoloRadius.lgAll),
      title: Text('Reset progress?', style: BoloTypography.subhead()),
      content: Text(
        "This clears every counter. It won't affect words or audio.",
        style: BoloTypography.body(color: BoloColors.ink2),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel',
              style: BoloTypography.utilityLabel(color: BoloColors.ink3)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: BoloColors.alert,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(borderRadius: BoloRadius.pillAll),
          ),
          child: Text('Reset',
              style: BoloTypography.utilityLabel(color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
