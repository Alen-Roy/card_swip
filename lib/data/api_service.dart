import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiService {
  static const _url2Items = 'https://api.mocklets.com/p26/mock1';
  static const _url9Items = 'https://api.mocklets.com/p26/mock2';

  Future<BillSection> fetchBills({bool use2Items = false}) async {
    final url = use2Items ? _url2Items : _url9Items;
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return BillSection.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load: ${response.statusCode}');
    }
  }
}
