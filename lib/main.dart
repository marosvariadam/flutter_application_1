import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/app/user_session.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('app_box');
  await initializeDateFormatting('hu', null);

  // Restore session role from secure storage (survives app restarts)
  await UserSession.instance.loadFromStorage();

  runApp(const App());
}

