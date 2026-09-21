import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Database
  await DatabaseHelper.instance.database;

  runApp(const SpendzApp());
}
