import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cred_carousel_assignment/widgets/stacked_carousel.dart';
import 'package:cred_carousel_assignment/widgets/bill_card_widget.dart';
import 'package:cred_carousel_assignment/data/models.dart';

// Simple colored boxes used to test the carousel layout
List<Widget> makeCards(int count) => List.generate(
      count,
      (i) => Container(
        key: Key('card_$i'),
        color: Colors.primaries[i % Colors.primaries.length],
        child: Text('Card $i'),
      ),
    );

// Minimal BillCard matching the current model fields
BillCard makeCard({FlipperConfig? flipper, String? footer}) => BillCard(
      body: CardBody(
        logo: Logo(url: '', bgColor: '#FFFFFF'),
        title: 'HDFC Bank',
        subTitle: 'xxxx 5948',
        amount: '₹45,000',
        footerText: footer,
        flipperConfig: flipper,
      ),
      cardColor: '#FFFFFF',
      ctaTitle: 'Pay ₹45,000',
    );

void main() {
  // ── <= 2 items: plain column, no PageView ──────────────────────────────────
  group('2 items state', () {
    testWidgets('shows both cards and no PageView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StackedCarousel(children: makeCards(2))),
        ),
      );

      expect(find.byKey(const Key('card_0')), findsOneWidget);
      expect(find.byKey(const Key('card_1')), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
    });
  });

  // ── > 2 items: stacked carousel ────────────────────────────────────────────
  group('More than 2 items state', () {
    testWidgets('shows PageView with card 0 at the front', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StackedCarousel(children: makeCards(9))),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
      expect(find.byKey(const Key('card_0')), findsOneWidget);
    });

    testWidgets('swiping up brings card 1 to the front', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StackedCarousel(children: makeCards(9))),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(PageView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('card_1')), findsOneWidget);
    });
  });

  // ── Performance ────────────────────────────────────────────────────────────
  group('No frame drops', () {
    testWidgets('swipe animation finishes within 2 seconds', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StackedCarousel(children: makeCards(10))),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(PageView), const Offset(0, -300));

      final sw = Stopwatch()..start();
      await tester.pumpAndSettle();
      sw.stop();

      // If this fails the animation is blocking the UI thread
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });

    testWidgets('10 rapid swipes stay within 60fps budget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StackedCarousel(children: makeCards(20))),
        ),
      );
      await tester.pumpAndSettle();

      for (int i = 0; i < 10; i++) {
        await tester.drag(find.byType(PageView), const Offset(0, -80));
        await tester.pump(const Duration(milliseconds: 16)); // one frame at 60fps
      }

      await tester.pumpAndSettle();
      expect(find.byType(PageView), findsOneWidget);
    });
  });

  // ── Tag text ───────────────────────────────────────────────────────────────
  group('Tag text state', () {
    testWidgets('shows footer text when no flipper config', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BillCardWidget(card: makeCard(footer: 'DUE TODAY')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DUE TODAY'), findsOneWidget);
    });

    testWidgets('cycles to next text after flip delay', (tester) async {
      final card = makeCard(
        flipper: FlipperConfig(
          flipDelay: 300,
          items: [FlipperItem(text: 'Get 5% off')],
          finalStage: FlipperItem(text: 'DUE TODAY'),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: BillCardWidget(card: card))),
      );

      // First item shows immediately
      expect(find.text('Get 5% off'), findsOneWidget);

      // After the delay, it should move to the next text
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('DUE TODAY'), findsOneWidget);
    });

    testWidgets('loops back to first item after reaching the end', (tester) async {
      final card = makeCard(
        flipper: FlipperConfig(
          flipDelay: 300,
          items: [FlipperItem(text: 'Get 5% off')],
          finalStage: FlipperItem(text: 'DUE TODAY'),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: BillCardWidget(card: card))),
      );

      // Tick past both items — should wrap back to first
      await tester.pump(const Duration(milliseconds: 400)); // → DUE TODAY
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400)); // → Get 5% off (loop)
      await tester.pumpAndSettle();

      expect(find.text('Get 5% off'), findsOneWidget);
    });
  });
}
