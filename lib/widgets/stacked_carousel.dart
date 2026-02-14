import 'dart:math';
import 'package:flutter/material.dart';

const double _cardHeight = 90;
const double _cardGap = 1;

class StackedCarousel extends StatefulWidget {
  final List<Widget> children;

  const StackedCarousel({super.key, required this.children});

  @override
  State<StackedCarousel> createState() => _StackedCarouselState();
}

class _StackedCarouselState extends State<StackedCarousel> {
  final _pageController = PageController();
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() => _page = _pageController.page ?? 0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.children.length;

    // <= 2 items: just show them in a simple column, no carousel needed
    if (count <= 2) {
      return Column(
        children: [
          for (int i = 0; i < count; i++) ...[
            widget.children[i],
            if (i < count - 1) const SizedBox(height: _cardGap),
          ],
        ],
      );
    }

    // > 2 items: stacked carousel
    final stackHeight = (_cardHeight * 2) + _cardGap + 28;

    // ── Z-order ──────────────────────────────────────────────────────────────
    // In a Stack the LAST child is on top.
    // Normally we want card 0 on top → render it last.
    // During a swipe from N → N+1 we want N+1 on top → render it last.
    final outgoing = _page.floor();
    final progress = _page - outgoing; // 0..1
    final transitioning = progress > 0.01;

    final indices = List.generate(count, (i) => i)
        .where((i) => (i - _page) >= -1.0 && (i - _page) <= 3.5)
        .toList();

    indices.sort((a, b) {
      if (transitioning) {
        if (a == outgoing && b == outgoing + 1) return -1; // a behind b
        if (b == outgoing && a == outgoing + 1) return 1;
      }
      return b.compareTo(a); // higher index = further back = render first
    });

    return SizedBox(
      height: stackHeight,
      child: Stack(
        children: [
          // Invisible PageView — only here to capture swipe gestures
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: count,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (_, __) => SizedBox(
                height: stackHeight,
                child: const ColoredBox(color: Colors.transparent)),
          ),

          // Cards rendered in Z-order
          for (final i in indices) _buildCard(i),
        ],
      ),
    );
  }

  Widget _buildCard(int index) {
    final diff = index - _page;

    // ── Leaving card (diff < 0): fold backward ────────────────────────────
    if (diff < 0) {
      final progress = (-diff).clamp(0.0, 1.0);
      final angle = -progress * pi / 2; // 0° → -90°
      final opacity = (1.0 - progress * 1.4).clamp(0.0, 1.0);
      final darken = progress * 0.45;

      return Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Opacity(
            opacity: opacity,
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0015) // perspective
                ..rotateX(angle), // fold top away from viewer
              alignment: Alignment.bottomCenter, // hinge at the bottom edge
              child: Stack(
                children: [
                  SizedBox(height: _cardHeight, child: widget.children[index]),
                  // Darkening overlay — card turning away from light
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withOpacity(darken),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── Normal stack card (diff >= 0) ─────────────────────────────────────
    final pos = diff.clamp(0.0, 3.5);

    // Y position
    double top;
    if (pos <= 1.0) {
      // Cards 0 and 1: sit at full card height apart
      top = pos * (_cardHeight + _cardGap);
    } else {
      // Cards 2+ peek below card 1
      top = (_cardHeight + _cardGap) + (pos - 1.0) * 18;
    }

    // Scale: cards deeper in the stack are slightly smaller
    final scale =
        pos <= 1.0 ? 1.0 : (1.0 - (pos - 1.0) * 0.04).clamp(0.88, 1.0);

    // Opacity: first two cards fully visible, rest fade
    final opacity = pos < 1.5 ? 1.0 : (1.0 - (pos - 1.5) * 0.3).clamp(0.5, 1.0);

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topCenter,
            child: SizedBox(height: _cardHeight, child: widget.children[index]),
          ),
        ),
      ),
    );
  }
}
