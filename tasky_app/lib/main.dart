import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/task_provider.dart';
import 'providers/team_provider.dart';
import 'providers/theme_provider.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale data for Vietnamese
  await initializeDateFormatting('vi', null);

  final prefs = await SharedPreferences.getInstance();
  final authProvider = AuthProvider(prefs: prefs);
  await authProvider.initialize();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Request notification permissions
  await notificationService.requestPermissions();

  runApp(TaskyBootstrap(
    authProvider: authProvider,
    prefs: prefs,
    notificationService: notificationService,
  ));
}

class TaskyBootstrap extends StatelessWidget {
  const TaskyBootstrap({
    super.key,
    required this.authProvider,
    required this.prefs,
    required this.notificationService,
  });

  final AuthProvider authProvider;
  final SharedPreferences prefs;
  final NotificationService notificationService;

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
        ChangeNotifierProxyProvider<AuthProvider, StatisticsProvider>(
          create: (_) => StatisticsProvider(api: ApiService()),
          update: (_, auth, statsProvider) {
            if (statsProvider == null) {
              return StatisticsProvider(api: auth.api);
            }
            return statsProvider;
          },
        ),
      ],
      child: const TaskyApp(),
    );
  }
}
