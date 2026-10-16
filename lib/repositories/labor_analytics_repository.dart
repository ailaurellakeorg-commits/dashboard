import '../models/dashboard_models.dart';

abstract interface class LaborAnalyticsRepository {
  Future<LaborAnalyticsData> load({
    required DashboardDateRange range,
    required List<LaborDepartment> departments,
  });
}

class DemoLaborAnalyticsRepository implements LaborAnalyticsRepository {
  const DemoLaborAnalyticsRepository();

  @override
  Future<LaborAnalyticsData> load({
    required DashboardDateRange range,
    required List<LaborDepartment> departments,
  }) async {
    final records = <DailyDepartmentLaborRecord>[];
    for (var dayIndex = 0; dayIndex < range.dayCount; dayIndex++) {
      final date = DateTime(
        range.start.year,
        range.start.month,
        range.start.day + dayIndex,
      );
      final departmentValues = <String, DepartmentLaborDay>{};
      final employeeValues = <String, EmployeeLaborDay>{};

      for (var index = 0; index < departments.length; index++) {
        final department = departments[index];
        var workedHours = 0.0;
        var overtimeHours = 0.0;
        var laborCost = 0.0;
        for (final (employeeIndex, employee) in department.employees.indexed) {
          final scheduled =
              date.weekday <= DateTime.friday &&
              (dayIndex + employeeIndex) % 8 != 7;
          if (!scheduled) {
            employeeValues[employee.code] = const EmployeeLaborDay(
              cost: 0,
              workedHours: 0,
              overtimeHours: 0,
            );
            continue;
          }

          final rate = employee.rateAmount ?? 0;
          if (employee.rateType == 'salary') {
            workedHours += 8;
            final cost = rate / 260;
            laborCost += cost;
            employeeValues[employee.code] = EmployeeLaborDay(
              cost: cost,
              workedHours: 8,
              overtimeHours: 0,
            );
            continue;
          }

          final hours = 7.25 + ((dayIndex + employeeIndex + index) % 4) * .25;
          final overtime = (dayIndex + employeeIndex + index) % 7 == 0
              ? .5
              : 0.0;
          workedHours += hours;
          overtimeHours += overtime;
          final cost = hours * rate + overtime * rate * 1.5;
          laborCost += cost;
          employeeValues[employee.code] = EmployeeLaborDay(
            cost: cost,
            workedHours: hours,
            overtimeHours: overtime,
          );
        }
        departmentValues[department.code] = DepartmentLaborDay(
          laborCost: laborCost,
          workedHours: workedHours,
          overtimeHours: overtimeHours,
        );
      }

      records.add(
        DailyDepartmentLaborRecord(
          date: date,
          departments: departmentValues,
          employees: employeeValues,
        ),
      );
    }

    return LaborAnalyticsData(dailyRecords: records);
  }
}
