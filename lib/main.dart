import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/app_theme.dart';
import 'repositories/dashboard_repository.dart';
import 'repositories/labor_analytics_repository.dart';
import 'repositories/labor_directory_repository.dart';
import 'ui/screens/dashboard/bloc/dashboard_bloc.dart';
import 'ui/screens/dashboard/bloc/dashboard_event.dart';
import 'ui/screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LaurelLakeDashboardApp());
}

class LaurelLakeDashboardApp extends StatelessWidget {
  const LaurelLakeDashboardApp({
    super.key,
    this.repository,
    this.laborDirectoryRepository,
    this.demoLaborDirectoryRepository,
    this.laborAnalyticsRepository,
  });

  final DashboardRepository? repository;
  final LaborDirectoryRepository? laborDirectoryRepository;
  final DemoLaborDirectoryRepository? demoLaborDirectoryRepository;
  final LaborAnalyticsRepository? laborAnalyticsRepository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Laurel Lake | Executive Dashboard',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: RepositoryProvider<DemoLaborDirectoryRepository>(
      create: (_) =>
          demoLaborDirectoryRepository ?? const DemoLaborDirectoryRepository(),
      child: RepositoryProvider<LaborAnalyticsRepository>(
        create: (_) =>
            laborAnalyticsRepository ?? const DemoLaborAnalyticsRepository(),
        child: RepositoryProvider<LaborDirectoryRepository>(
          create: (_) =>
              laborDirectoryRepository ?? HttpLaborDirectoryRepository(),
          child: BlocProvider(
            create: (_) => DashboardBloc(
              repository: repository ?? DemoDashboardRepository(),
            )..add(const DashboardLoadRequested()),
            child: const DashboardScreen(),
          ),
        ),
      ),
    ),
  );
}
