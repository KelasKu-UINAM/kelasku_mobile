import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'features/auth/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await initializeDateFormatting('id_ID');

  // Create a ProviderContainer so we can attempt auto-login before runApp.
  final container = ProviderContainer();

  // Try to restore a previous session from secure storage.
  await container.read(authProvider.notifier).tryAutoLogin();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const KelaskuApp(),
    ),
  );
}
