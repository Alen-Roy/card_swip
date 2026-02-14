import 'package:flutter/material.dart';
import 'dart:async';
import '../data/models.dart';

class BillCardWidget extends StatefulWidget {
  final BillCard card;
  const BillCardWidget({super.key, required this.card});

  @override
  State<BillCardWidget> createState() => _BillCardWidgetState();
}

class _BillCardWidgetState extends State<BillCardWidget> {
  Timer? _timer;
  int _index = 0;
  late List<String> _texts;

  @override
  void initState() {
    super.initState();
    final flipper = widget.card.body.flipperConfig;

    if (flipper != null) {
      _texts = [...flipper.items.map((e) => e.text), flipper.finalStage.text];
      _timer = Timer.periodic(Duration(milliseconds: flipper.flipDelay), (_) {
        setState(() {
          _index = (_index + 1) % _texts.length;
        });
      });
    } else {
      _texts = [widget.card.body.footerText ?? ''];
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = widget.card.body;
    final cardColor = _hexColor(widget.card.cardColor);
    final isLight = cardColor.computeLuminance() > 0.4;
    final textColor = isLight ? Colors.black87 : Colors.white;

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _BankLogo(url: body.logo.url, bgColor: body.logo.bgColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  body.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body.subTitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isLight ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.card.ctaTitle,
                  style: TextStyle(
                    color: isLight ? Colors.white : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              _SlotText(text: _texts.isNotEmpty ? _texts[_index] : ''),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Bank logo ─────────────────────────────────────────────────────────────────
class _BankLogo extends StatelessWidget {
  final String url;
  final String bgColor;
  const _BankLogo({required this.url, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _hexColor(bgColor),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.account_balance, size: 20, color: Colors.grey),
        ),
      ),
    );
  }
}

// ── Slot text ─────────────────────────────────────────────────────────────────
// Old text slides up and fades out.
// New text slides up from below and fades in.
// Uses a StatefulWidget + AnimationController so we can control the direction
// properly — AnimatedSwitcher alone can't do this cleanly.
class _SlotText extends StatefulWidget {
  final String text;
  const _SlotText({super.key, required this.text});

  @override
  State<_SlotText> createState() => _SlotTextState();
}

class _SlotTextState extends State<_SlotText>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late String _shown;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _shown = widget.text;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _ctrl.value = 1.0; // start fully visible
  }

  @override
  void didUpdateWidget(covariant _SlotText old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text && widget.text.isNotEmpty) {
      // Phase 1: slide current text up and fade out
      _leaving = true;
      _ctrl.reverse().then((_) {
        if (!mounted) return;
        // swap to new text, then slide in from below
        setState(() {
          _shown = widget.text;
          _leaving = false;
        });
        _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shown.isEmpty) return const SizedBox.shrink();

    final color = _tagColor(_shown);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        // leaving → slide up (negative y). entering → slide in from below (positive y → 0)
        final dy = _leaving ? (1 - t) * -14.0 : (1 - t) * 14.0;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Opacity(
            opacity: t,
            child: Text(
              _shown,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Color _tagColor(String t) {
    final u = t.toUpperCase();
    if (u.contains('OVERDUE')) return const Color(0xFFFF453A);
    if (u.contains('TODAY')) return const Color(0xFFFF9F0A);
    return const Color(0xFF00D09C);
  }
}

Color _hexColor(String hex) {
  try {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  } catch (_) {
    return Colors.white;
  }
}
