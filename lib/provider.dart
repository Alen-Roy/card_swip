import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'data/api_service.dart';
import 'data/models.dart';

final use2ItemsProvider = StateProvider<bool>((ref) => false);

final billsProvider = FutureProvider<BillSection>((ref) {
  final use2Items = ref.watch(use2ItemsProvider);
  return ApiService().fetchBills(use2Items: use2Items);
});
