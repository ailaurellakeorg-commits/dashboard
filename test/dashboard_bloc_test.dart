import 'package:flutter_test/flutter_test.dart';
import 'package:laurel_lake_dashboard/models/dashboard_models.dart';
import 'package:laurel_lake_dashboard/repositories/dashboard_repository.dart';
import 'package:laurel_lake_dashboard/ui/screens/dashboard/bloc/dashboard_bloc.dart';
import 'package:laurel_lake_dashboard/ui/screens/dashboard/bloc/dashboard_event.dart';
import 'package:laurel_lake_dashboard/ui/screens/dashboard/bloc/dashboard_state.dart';

void main() {
  test('loads daily dashboard data for the requested range', () async {
    final bloc = DashboardBloc(repository: DemoDashboardRepository());
    final range = DashboardDateRange.month(2026, 8);
    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<DashboardLoading>(),
        isA<DashboardLoaded>().having(
          (state) => state.data.dailyRecords.length,
          'daily records',
          30,
        ),
      ]),
    );

    bloc.add(DashboardLoadRequested(range: range));

    await states;
    await bloc.close();
  });

  test('loads a custom range spanning two months', () async {
    final bloc = DashboardBloc(repository: DemoDashboardRepository());
    final range = DashboardDateRange(
      start: DateTime(2026, 7, 29),
      end: DateTime(2026, 8, 4),
    );
    final states = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<DashboardLoading>(),
        isA<DashboardLoaded>()
            .having(
              (state) => state.data.dailyRecords.length,
              'daily records',
              7,
            )
            .having(
              (state) => state.data.dailyRecords.last.date,
              'last date',
              DateTime(2026, 8, 4),
            ),
      ]),
    );

    bloc.add(DashboardDateRangeChanged(range));

    await states;
    await bloc.close();
  });

  test('daily detail records reconcile to dashboard totals', () async {
    final repository = DemoDashboardRepository();
    final data = await repository.loadDashboard(
      range: DashboardDateRange(
        start: DateTime(2026, 9, 15),
        end: DateTime(2026, 9, 25),
      ),
    );

    expect(data.bedIds, hasLength(160));
    expect(data.employees, hasLength(80));
    expect(data.missingDates, [DateTime(2026, 9, 24)]);
    for (final record in data.dailyRecords) {
      expect(
        record.bedOccupancyHours.values.where((hours) => hours > 0).length,
        record.census,
      );
      expect(
        record.employeeLabor.values.fold<double>(
          0,
          (sum, detail) => sum + detail.hours,
        ),
        closeTo(record.laborHours, .001),
      );
      expect(
        record.employeeLabor.values.fold<double>(
          0,
          (sum, detail) => sum + detail.cost,
        ),
        closeTo(record.laborCost, .001),
      );
    }
  });

  test('marks entirely missing days without treating them as zero', () async {
    final repository = DemoDashboardRepository();
    final data = await repository.loadDashboard(
      range: DashboardDateRange.month(2026, 9),
    );

    expect(data.expectedDayCount, 30);
    expect(data.reportedDayCount, 28);
    expect(data.missingDates, [DateTime(2026, 9, 10), DateTime(2026, 9, 24)]);
    expect(
      data.censusTrend.where((point) => point.value == null),
      hasLength(2),
    );
  });
}
