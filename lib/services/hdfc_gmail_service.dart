import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/imported_transaction.dart';

class HdfcGmailService {
  Future<List<ImportedTransaction>> fetchTransactions() async {
    final url = AppConfig.appsScriptUrl;
    if (url.isEmpty || url == 'YOUR_APPS_SCRIPT_URL_HERE') {
      throw Exception('Apps Script URL is not configured.');
    }

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true && decoded['transactions'] != null) {
          final List<dynamic> transactionsJson = decoded['transactions'];
          return transactionsJson
              .map((json) => ImportedTransaction.fromJson(json))
              .toList();
        } else {
          throw Exception('API returned unsuccessful response or missing transactions.');
        }
      } else {
        throw Exception('Failed to fetch transactions (HTTP ${response.statusCode}).');
      }
    } on FormatException {
      throw Exception('Failed to parse API response. Invalid JSON.');
    } catch (e) {
      throw Exception('Network error or timeout: $e');
    }
  }
}
