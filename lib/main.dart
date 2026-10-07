import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/app_theme.dart';
import 'repositories/dashboard_repository.dart';
import 'ui/screens/dashboard/bloc/dashboard_bloc.dart';
import 'ui/screens/dashboard/bloc/dashboard_event.dart';
import 'ui/screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LaurelLakeDashboardApp());
}

class LaurelLakeDashboardApp extends StatelessWidget {
  const LaurelLakeDashboardApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Laurel Lake | Executive Dashboard',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: BlocProvider(
      create: (_) =>
          DashboardBloc(repository: DemoDashboardRepository())
            ..add(const DashboardLoadRequested()),
      child: const DashboardScreen(),
    ),
  );
}
