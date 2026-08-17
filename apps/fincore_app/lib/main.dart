import 'package:fincore_app/app/app.dart';
import 'package:fincore_app/features/settings/data/services/automatic_backup_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeAutomaticBackupBackground();
  runApp(const ProviderScope(child: FincoreApp()));
}
