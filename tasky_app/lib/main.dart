import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/task_provider.dart';
import 'providers/team_provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale data for Vietnamese
  await initializeDateFormatting('vi', null);

  final prefs = await SharedPreferences.getInstance();
  final authProvider = AuthProvider(prefs: prefs);
  await authProvider.initialize();

  runApp(TaskyBootstrap(authProvider: authProvider, prefs: prefs));
}

class TaskyBootstrap extends StatelessWidget {
  const TaskyBootstrap({
    super.key,
    required this.authProvider,
    required this.prefs,
  });

  final AuthProvider authProvider;
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(prefs: prefs),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) => TaskProvider(api: authProvider.api),
          update: (_, auth, taskProvider) {
            final provider = taskProvider ?? TaskProvider(api: auth.api);
            provider.updateApi(auth.api);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, TeamProvider>(
          create: (_) => TeamProvider(api: authProvider.api),
          update: (_, auth, teamProvider) {
            final provider = teamProvider ?? TeamProvider(api: auth.api);
            provider.updateApi(auth.api);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(api: authProvider.api),
          update: (_, auth, notifProvider) {
            final provider =
                notifProvider ?? NotificationProvider(api: auth.api);
            provider.updateApi(auth.api);
            if (auth.isAuthenticated) {
              provider.startPolling();
            } else {
              provider.stopPolling();
            }
            return provider;
          },
        ),
      ],
      child: const TaskyApp(),
    );
  }
}
