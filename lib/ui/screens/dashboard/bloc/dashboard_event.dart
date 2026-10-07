import '../../../../models/dashboard_models.dart';

sealed class DashboardEvent {
  const DashboardEvent();
}

class DashboardLoadRequested extends DashboardEvent {
  const DashboardLoadRequested({this.range});

  final DashboardDateRange? range;
}

class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested();
}

class DashboardDateRangeChanged extends DashboardEvent {
  const DashboardDateRangeChanged(this.range);

  final DashboardDateRange range;
}
