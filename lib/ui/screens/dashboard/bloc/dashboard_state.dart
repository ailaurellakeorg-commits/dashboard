import '../../../../models/dashboard_models.dart';

sealed class DashboardState {
  const DashboardState({required this.range});

  final DashboardDateRange range;
}

class DashboardInitial extends DashboardState {
  const DashboardInitial({required super.range});
}

class DashboardLoading extends DashboardState {
  const DashboardLoading({required super.range});
}

class DashboardLoaded extends DashboardState {
  const DashboardLoaded({required super.range, required this.data});

  final DashboardData data;
}

class DashboardFailure extends DashboardState {
  const DashboardFailure({required super.range, required this.message});

  final String message;
}
