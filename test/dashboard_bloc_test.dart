import 'package:flutter_test/flutter_test.dart';
import 'package:laurel_lake_dashboard/models/dashboard_models.dart';
import 'package:laurel_lake_dashboard/repositories/dashboard_repository.dart';
import 'package:laurel_lake_dashboard/ui/screens/dashboard/bloc/dashboard_bloc.dart';
import 'package:laurel_lake_dashboard/ui/screens/dashboard/bloc/dashboard_event.dart';
import 'package:laurel_lake_dashboard/ui/screens/dashboard/bloc/dashboard_state.dart';

void main() {
  test('defaults to current month and generates October detail data', () async {
    final repository = DemoDashboardRepository(
      now: () => DateTime(2026, 10, 7, 15),
    );
    final bloc = DashboardBloc(repository: repository);
    final loaded = bloc.stream.firstWhere((state) => state is DashboardLoaded);
    bloc.add(const DashboardLoadRequested());
    final state = await loaded as DashboardLoaded;
    expect(state.range.start, DateTime(2026, 10));
    expect(state.range.end, DateTime(2026, 10, 7));
    expect(state.data.dailyRecords, hasLength(7));
    expect(state.data.bedIds, hasLength(160));
    expect(state.data.employees, hasLength(80));
    expect(state.data.totalLaborCost, greaterThan(0));
    expect(state.data.totalExpense, greaterThan(0));
    await bloc.close();
  });

  test(
    'available dates and records advance across a year without restarting',
    () async {
      var today = DateTime(2026, 12, 31);
      final repository = DemoDashboardRepository(now: () => today);
      final december = await repository.loadDashboard(
        range: DashboardDateRange.month(2026, 12),
      );
      expect(december.dailyRecords, hasLength(31));
      today = DateTime(2027, 1, 2);
      expect(repository.availableRange.end, today);
      final data = await repository.loadDashboard(
        range: DashboardDateRange(start: DateTime(2026, 12, 30), end: today),
      );
      expect(data.dailyRecords, hasLength(4));
      expect(data.dailyRecords.last.date, today);
      expect(data.missingDates, isEmpty);
    },
  );

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
