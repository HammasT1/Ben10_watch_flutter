import 'package:flutter/material.dart';

import '../models/alien.dart';
import 'alien_image.dart';

/// Opens a swipeable sheet of alien profile cards starting at
/// [initialIndex]. When [onSelect] is given, a button lets the user put the
/// currently shown alien on the dial.
Future<void> showAlienInfoSheet(
  BuildContext context, {
  required List<Alien> aliens,
  required int initialIndex,
  ValueChanged<int>? onSelect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF07140D),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.86,
      child: _AlienInfoSheet(
        aliens: aliens,
        initialIndex: initialIndex,
        onSelect: onSelect,
      ),
    ),
  );
}

class _AlienInfoSheet extends StatefulWidget {
  const _AlienInfoSheet({
    required this.aliens,
    required this.initialIndex,
    this.onSelect,
  });

  final List<Alien> aliens;
  final int initialIndex;
  final ValueChanged<int>? onSelect;

  @override
  State<_AlienInfoSheet> createState() => _AlienInfoSheetState();
}

class _AlienInfoSheetState extends State<_AlienInfoSheet> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _page = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.aliens[_page].color;
    return SafeArea(
      top: false,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: widget.aliens.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) =>
                  AlienInfoCard(alien: widget.aliens[index]),
            ),
          ),
          _buildDots(color),
          if (widget.onSelect != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('select-alien'),
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onSelect!(_page);
                  },
                  icon: const Icon(Icons.radio_button_checked),
                  label: const Text(
                    'SET ON DIAL',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDots(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < widget.aliens.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _page ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == _page ? color : Colors.white24,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

/// One alien's profile: silhouette, bio, powers and stat bars.
class AlienInfoCard extends StatelessWidget {
  const AlienInfoCard({super.key, required this.alien});

  final Alien alien;

  @override
  Widget build(BuildContext context) {
    final highlight = alienHighlight(alien.color);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 150,
              height: 150,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    alien.color.withValues(alpha: 0.35),
                    alien.color.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
              child: AlienImage(alien: alien, tint: highlight),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              alien.name.toUpperCase(),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: highlight,
                shadows: [Shadow(color: alien.color, blurRadius: 18)],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '${alien.species}  •  ${alien.homeworld}',
              style: const TextStyle(color: Colors.white60, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            alien.description,
            style: const TextStyle(color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 18),
          _sectionLabel('POWERS'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final power in alien.powers)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: alien.color.withValues(alpha: 0.12),
                    border: Border.all(
                      color: alien.color.withValues(alpha: 0.6),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    power,
                    style: TextStyle(color: highlight, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _sectionLabel('STATS'),
          const SizedBox(height: 8),
          for (final entry in alien.stats.asMap.entries)
            _StatBar(label: entry.key, value: entry.value, color: alien.color),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 2.5,
        fontWeight: FontWeight.w700,
        color: Colors.white54,
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value / 10),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
