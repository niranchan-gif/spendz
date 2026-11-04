import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Database safely
  try {
    await DatabaseHelper.instance.database;
  } catch (e, stack) {
    debugPrint('Database initialization warning: $e\n$stack');
  }

  runApp(const SpendzApp());
}
