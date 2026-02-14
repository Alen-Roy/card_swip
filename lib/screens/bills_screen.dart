import 'package:creed_assignment/widgets/stacked_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models.dart';
import '../provider.dart';
import '../widgets/bill_card_widget.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);
    final use2Items = ref.watch(use2ItemsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0C0D),
        elevation: 0,
        title: const Text(
          'CRED',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(use2ItemsProvider.notifier).state = !use2Items,
            child: Text(
              use2Items ? 'Show 9 items' : 'Show 2 items',
              style: const TextStyle(color: Color(0xFF00D09C), fontSize: 12),
            ),
          ),
        ],
      ),
      body: billsAsync.when(
        data: (section) => _Body(section: section),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00D09C)),
        ),
        error: (err, _) => _ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(billsProvider),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final BillSection section;
  const _Body({required this.section});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                section.title.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D09C).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${section.cards.length}',
                  style: const TextStyle(
                    color: Color(0xFF00D09C),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (section.cards.length > 2)
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'view all >',
                    style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          StackedCarousel(
            children: section.cards
                .map((card) => BillCardWidget(card: card))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFFF453A)),
            const SizedBox(height: 16),
            const Text(
              'Failed to load bills',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D09C),
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
