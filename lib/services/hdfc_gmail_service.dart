import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../config/app_config.dart';
import '../models/imported_transaction.dart';

class HdfcGmailService {
  Future<List<ImportedTransaction>> fetchTransactions({required DateTime startDate, required DateTime endDate}) async {
    final baseUrl = AppConfig.appsScriptUrl;
    if (baseUrl.isEmpty || baseUrl == 'YOUR_APPS_SCRIPT_URL_HERE') {
      throw Exception('Apps Script URL is not configured.');
    }

    try {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      final String fromStr = formatter.format(startDate);
      final String toStr = formatter.format(endDate);
      
      final url = '$baseUrl?from=$fromStr&to=$toStr';
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true && decoded['transactions'] != null) {
          final List<dynamic> transactionsJson = decoded['transactions'];
          
          final parsedTransactions = transactionsJson
              .map((json) => ImportedTransaction.fromJson(json))
              .toList();
              
          return parsedTransactions;
        } else {
          final errorMsg = decoded['error'] ?? 'Received invalid or empty data from the sync service.';
          throw Exception(errorMsg);
        }
      } else {
        throw Exception('Failed to connect to Spendz sync service (HTTP ${response.statusCode}).');
      }
    } on FormatException {
      throw Exception('Unable to process the sync response. Invalid format.');
    } catch (e) {
      throw Exception('Unable to connect to Spendz sync service. Please check your internet connection.');
    }
  }
}
