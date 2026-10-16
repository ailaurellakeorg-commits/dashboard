import 'package:flutter_test/flutter_test.dart';
import 'package:laurel_lake_dashboard/models/dashboard_models.dart';
import 'package:laurel_lake_dashboard/repositories/labor_analytics_repository.dart';

void main() {
  test('demo repository creates deterministic daily department data', () async {
    const repository = DemoLaborAnalyticsRepository();
    const department = LaborDepartment(
      code: '53',
      name: 'Housekeeping',
      employees: [
        LaborEmployee(
          code: '1',
          name: 'Example Employee',
          rateType: 'hourly',
          rateAmount: 30,
        ),
      ],
    );
    final range = DashboardDateRange(
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 3),
    );

    final first = await repository.load(
      range: range,
      departments: const [department],
    );
    final second = await repository.load(
      range: range,
      departments: const [department],
    );

    expect(first.dailyRecords, hasLength(3));
    expect(first.totalLaborCost({'53'}), greaterThan(0));
    expect(first.totalWorkedHours({'53'}), greaterThan(0));
    expect(
      first.dailyRecords.first.departments['53']?.laborCost,
      closeTo(240, .001),
    );
    expect(first.dailyRecords.first.employees['1']?.workedHours, 7.25);
    expect(first.dailyRecords.first.employees['1']?.cost, closeTo(240, .001));
    expect(
      first.dailyRecords.first.departments['53']?.laborCost,
      second.dailyRecords.first.departments['53']?.laborCost,
    );
    expect(first.departmentCostTrend('53'), hasLength(3));
    expect(
      first.departmentCostTrend('53').map((point) => point.value).toSet(),
      hasLength(greaterThan(1)),
    );
    expect(
      first.totalCostTrend({'53'}).first.value,
      first.dailyRecords.first.departments['53']?.laborCost,
    );
  });
}
