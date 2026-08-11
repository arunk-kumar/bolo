import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/bolo_colors.dart';
import '../../core/theme/bolo_dimens.dart';
import '../../core/theme/bolo_typography.dart';
import '../game_naming/naming_game_screen.dart';
import '../parent/parent_gate.dart';
import '../parent/progress_screen.dart';
import '../parent/progress_service.dart';

/// Bolo's home surface — a vertical stage-map that renders the child's
/// journey through the vocabulary. Mirrors Design System v0.2 §03 · screen 2.
///
/// Progression rule (MVP): the first *unmastered* stage is `current`; every
/// stage after it is `locked`. Progress is hard-coded for now — the real
/// counters land when the progress repository is wired in.
class StageMapScreen extends ConsumerStatefulWidget {
  const StageMapScreen({super.key});

  @override
  ConsumerState<StageMapScreen> createState() => _StageMapScreenState();
}

class _StageMapScreenState extends ConsumerState<StageMapScreen> {
  // MVP: static stage list mirroring the 5-stage journey in the spec.
  // Each `category` string matches a category in core/words.yaml so we can
  // filter the round pool later. Progress values (done/total) are placeholder
  // until the progress repository lands.
  // 8 stages mirror the 8 content categories. `total` is what the child
  // must master to unlock the next stage; category strings match
  // core/words.yaml. Order = curriculum progression (concrete → abstract).
  static const _stages = <_StageDef>[
    _StageDef(id: 'animals',  name: 'Animals',  emoji: '🐘', category: 'animals',  total: 10),
    _StageDef(id: 'food',     name: 'Food',     emoji: '🍎', category: 'food',     total: 10),
    _StageDef(id: 'family',   name: 'Family',   emoji: '👨‍👩‍👧', category: 'family', total: 10),
    _StageDef(id: 'body',     name: 'My Body',  emoji: '👁',  category: 'body',     total: 10, lockedReason: 'UNLOCKS TOMORROW'),
    _StageDef(id: 'objects',  name: 'Things',   emoji: '🧸', category: 'objects',  total: 10, lockedReason: 'STAGE 5 · LOCKED'),
    _StageDef(id: 'colours',  name: 'Colours',  emoji: '🎨', category: 'colours',  total: 10, lockedReason: 'STAGE 6 · LOCKED'),
    _StageDef(id: 'vehicles', name: 'Vehicles', emoji: '🚗', category: 'vehicles', total: 10, lockedReason: 'STAGE 7 · LOCKED'),
    _StageDef(id: 'nature',   name: 'Outside',  emoji: '🌳', category: 'nature',   total: 10, lockedReason: 'STAGE 8 · LOCKED'),
  ];

  @override
  Widget build(BuildContext context) {
    // Real progress from SharedPreferences via ProgressService.
    // Each round in the naming game bumps progressBumpProvider, which
    // invalidates progressSummaryProvider and rebuilds this widget.
    final summary = ref.watch(progressSummaryProvider);
    final progress = summary.byCategory;
    final stageStates = _computeStageStates(progress);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: BoloLayout.contentMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const _Header(),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: _stages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, i) {
                        final def = _stages[i];
                        final state = stageStates[i];
                        // Category counters can exceed `total` if the child
                        // keeps playing after mastering; clamp for display.
                        final rawDone = progress[def.category] ?? 0;
                        final done = rawDone > def.total ? def.total : rawDone;
                        return _StageRow(
                          def: def,
                          state: state,
                          done: done,
                          onTap: state == _StageState.locked
                              ? null
                              : () => _openStage(context, def),
                        );
                      },
                    ),
                  ),
                  const _BottomNav(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // First unmastered stage → current; anything after → locked; everything
  // before → done. A stage with an explicit lockedReason stays locked even
  // when technically reachable — for the "unlocks tomorrow" cooldown case.
  List<_StageState> _computeStageStates(Map<String, int> progress) {
    final out = <_StageState>[];
    var currentAssigned = false;
    for (final def in _stages) {
      final done = progress[def.category] ?? 0;
      if (def.lockedReason != null) {
        out.add(_StageState.locked);
        continue;
      }
      if (done >= def.total) {
        out.add(_StageState.done);
      } else if (!currentAssigned) {
        out.add(_StageState.current);
        currentAssigned = true;
      } else {
        out.add(_StageState.locked);
      }
    }
    return out;
  }

  void _openStage(BuildContext context, _StageDef def) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NamingGameScreen(
          category: def.category,
          title: def.name,
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HI, LITTLE ONE',
                  style: BoloTypography.utilityLabel(color: BoloColors.ink3),
                ),
                const SizedBox(height: 4),
                Text(
                  "Let's play",
                  style: BoloTypography.screenTitle(),
                ),
              ],
            ),
          ),
          const _LangToggle(),
        ],
      ),
    );
  }
}

// EN / + language pill. `+` is a Phase 2 placeholder showing a
// "Coming soon" tooltip on tap.
class _LangToggle extends StatelessWidget {
  const _LangToggle();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: BoloColors.paper2,
        border: Border.all(color: BoloColors.paper3),
        borderRadius: BoloRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: const BoxDecoration(
              color: BoloColors.saffron,
              borderRadius: BoloRadius.pillAll,
            ),
            child: Text(
              'EN',
              style: BoloTypography.utilityLabel(color: Colors.white)
                  .copyWith(letterSpacing: 0.6),
            ),
          ),
          Tooltip(
            message: 'More languages coming soon',
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 2),
                      backgroundColor: BoloColors.ink2,
                      content: Text(
                        'More languages coming soon — Hindi is next.',
                        style: BoloTypography.body(color: Colors.white),
                      ),
                    ),
                  );
              },
              borderRadius: BoloRadius.pillAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                child: Text(
                  '+',
                  style: BoloTypography.utilityLabel(color: BoloColors.ink3)
                      .copyWith(fontSize: 14, letterSpacing: 0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stage row ─────────────────────────────────────────────────────

enum _StageState { done, current, locked }

class _StageDef {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final int total;
  final String? lockedReason;

  const _StageDef({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.total,
    this.lockedReason,
  });
}

class _StageRow extends StatelessWidget {
  final _StageDef def;
  final _StageState state;
  final int done;
  final VoidCallback? onTap;

  const _StageRow({
    required this.def,
    required this.state,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = state == _StageState.current;
    final isDone = state == _StageState.done;
    final isLocked = state == _StageState.locked;

    final Color bg;
    final Color border;
    final List<BoxShadow> shadow;
    if (isCurrent) {
      bg = BoloColors.turmeric;
      border = BoloColors.saffron;
      shadow = BoloShadow.wordCard;
    } else if (isDone) {
      bg = BoloColors.sage.withValues(alpha: 0.08);
      border = BoloColors.sage.withValues(alpha: 0.28);
      shadow = BoloShadow.card;
    } else {
      bg = BoloColors.paper2;
      border = BoloColors.paper3;
      shadow = BoloShadow.card;
    }

    final row = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: isCurrent ? 2 : 1),
        borderRadius: BoloRadius.mdAll,
        boxShadow: isLocked ? const [] : shadow,
      ),
      child: Row(
        children: [
          _StageIcon(state: state, emoji: def.emoji),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  def.name,
                  style: BoloTypography.subhead(
                    color: isCurrent ? BoloColors.ink : BoloColors.ink,
                  ).copyWith(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  _metaText(),
                  style: BoloTypography.utilityLabel(
                    color: isCurrent
                        ? BoloColors.saffronD
                        : BoloColors.ink3,
                  ),
                ),
              ],
            ),
          ),
          if (isLocked)
            const Icon(Icons.lock_rounded,
                size: 20, color: BoloColors.ink3)
          else
            const Icon(Icons.chevron_right_rounded,
                size: 24, color: BoloColors.ink2),
        ],
      ),
    );

    // Whole row is one big tap target — 80pt+ tall to meet the kids
    // guideline in BoloLayout.minTap.
    return Opacity(
      opacity: isLocked ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BoloRadius.mdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: BoloRadius.mdAll,
          child: row,
        ),
      ),
    );
  }

  String _metaText() {
    switch (state) {
      case _StageState.done:
        return '${def.total} / ${def.total} · MASTERED';
      case _StageState.current:
        return '$done / ${def.total} · KEEP GOING';
      case _StageState.locked:
        return def.lockedReason ?? 'LOCKED';
    }
  }
}

class _StageIcon extends StatelessWidget {
  final _StageState state;
  final String emoji;

  const _StageIcon({required this.state, required this.emoji});

  @override
  Widget build(BuildContext context) {
    final isDone = state == _StageState.done;
    final isCurrent = state == _StageState.current;

    final Color fill;
    final Color border;
    if (isDone) {
      fill = BoloColors.sage;
      border = BoloColors.sage;
    } else if (isCurrent) {
      fill = Colors.white;
      border = BoloColors.saffron;
    } else {
      fill = BoloColors.paper;
      border = BoloColors.paper3;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 2),
      ),
      alignment: Alignment.center,
      child: isDone
          ? const Icon(Icons.check_rounded,
              size: 24, color: Colors.white)
          : Text(
              emoji,
              style: const TextStyle(fontSize: 22),
            ),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────

class _BottomNav extends ConsumerWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: BoloColors.paper3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavItem(
            icon: '🏠',
            label: 'Home',
            active: true,
            onTap: () {},
          ),
          _NavItem(
            icon: '💬',
            label: 'Phrases',
            active: false,
            onTap: () => _showComingSoon(context, 'Phrases'),
          ),
          _NavItem(
            icon: '🔒',
            label: 'Parent',
            active: false,
            onTap: () => _openParent(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _openParent(BuildContext context, WidgetRef ref) async {
    final ok = await ParentGate.ensure(ref, context);
    if (!context.mounted || !ok) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProgressScreen()),
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: BoloColors.ink2,
          content: Text(
            '$label — coming soon.',
            style: BoloTypography.body(color: Colors.white),
          ),
        ),
      );
  }
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? BoloColors.saffron : BoloColors.ink3;
    return InkWell(
      onTap: onTap,
      borderRadius: BoloRadius.mdAll,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: BoloTypography.utilityLabel(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
