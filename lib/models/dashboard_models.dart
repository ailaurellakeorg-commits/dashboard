import 'package:flutter/material.dart';

class DashboardDateRange {
  const DashboardDateRange({required this.start, required this.end});

  factory DashboardDateRange.month(int year, int month) => DashboardDateRange(
    start: DateTime(year, month),
    end: DateTime(year, month + 1, 0),
  );

  final DateTime start;
  final DateTime end;

  // Count calendar dates independently of daylight-saving clock changes.
  int get dayCount =>
      DateTime.utc(
        end.year,
        end.month,
        end.day,
      ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
      1;

  List<DateTime> get dates => List.generate(
    dayCount,
    (index) => DateTime(start.year, start.month, start.day + index),
  );

  bool contains(DateTime date) => !date.isBefore(start) && !date.isAfter(end);
}

class DailyDashboardRecord {
  const DailyDashboardRecord({
    required this.date,
    required this.census,
    required this.laborHours,
    required this.overtimeHours,
    required this.laborCost,
    required this.nursingExpense,
    required this.dietaryExpense,
    required this.housekeepingExpense,
    required this.therapyExpense,
    required this.bedOccupancyHours,
    required this.employeeLabor,
  });

  final DateTime date;
  final int census;
  final double laborHours;
  final double overtimeHours;
  final double laborCost;
  final double nursingExpense;
  final double dietaryExpense;
  final double housekeepingExpense;
  final double therapyExpense;
  final Map<String, double> bedOccupancyHours;
  final Map<String, EmployeeLaborDetail> employeeLabor;

  double get totalExpense =>
      nursingExpense + dietaryExpense + housekeepingExpense + therapyExpense;
}

class EmployeeLaborDetail {
  const EmployeeLaborDetail({
    required this.employeeId,
    required this.employeeName,
    required this.role,
    required this.hours,
    required this.cost,
  });

  final String employeeId;
  final String employeeName;
  final String role;
  final double hours;
  final double cost;
}

class LaborDepartment {
  const LaborDepartment({
    required this.code,
    required this.name,
    required this.employees,
  });

  factory LaborDepartment.fromJson(Map<String, dynamic> json) =>
      LaborDepartment(
        code: json['code'] as String,
        name: json['name'] as String,
        employees: (json['employees'] as List<dynamic>)
            .map(
              (employee) =>
                  LaborEmployee.fromJson(employee as Map<String, dynamic>),
            )
            .toList(),
      );

  final String code;
  final String name;
  final List<LaborEmployee> employees;
}

class LaborEmployee {
  const LaborEmployee({
    required this.code,
    required this.name,
    required this.rateType,
    required this.rateAmount,
  });

  factory LaborEmployee.fromJson(Map<String, dynamic> json) {
    final amount = json['rateAmount'];
    return LaborEmployee(
      code: json['code'] as String,
      name: json['name'] as String,
      rateType: json['rateType'] as String?,
      rateAmount: amount is num ? amount.toDouble() : null,
    );
  }

  final String code;
  final String name;
  final String? rateType;
  final double? rateAmount;

  String get rateSubtitle {
    final amount = rateAmount;
    final type = rateType;
    if (amount == null || type == null) return 'Rate unavailable';

    final amountText = amount == amount.truncateToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    return type == 'hourly'
        ? 'Hourly · \$$amountText/hr'
        : 'Salary · \$$amountText';
  }
}

enum LaborDisplayMode { demo, live }

class DepartmentLaborDay {
  const DepartmentLaborDay({
    required this.laborCost,
    required this.workedHours,
    required this.overtimeHours,
  });

  final double laborCost;
  final double workedHours;
  final double overtimeHours;
}

class EmployeeLaborDay {
  const EmployeeLaborDay({
    required this.cost,
    required this.workedHours,
    required this.overtimeHours,
  });

  final double cost;
  final double workedHours;
  final double overtimeHours;
}

class DailyDepartmentLaborRecord {
  const DailyDepartmentLaborRecord({
    required this.date,
    required this.departments,
    required this.employees,
  });

  final DateTime date;
  final Map<String, DepartmentLaborDay> departments;
  final Map<String, EmployeeLaborDay> employees;
}

class LaborAnalyticsData {
  const LaborAnalyticsData({required this.dailyRecords});

  final List<DailyDepartmentLaborRecord> dailyRecords;

  double totalLaborCost(Set<String> departmentCodes) =>
      _sumFor(departmentCodes, (day) => day.laborCost);

  double totalWorkedHours(Set<String> departmentCodes) =>
      _sumFor(departmentCodes, (day) => day.workedHours);

  double totalOvertimeHours(Set<String> departmentCodes) =>
      _sumFor(departmentCodes, (day) => day.overtimeHours);

  List<TrendPoint> totalCostTrend(Set<String> departmentCodes) => [
    for (final record in dailyRecords)
      TrendPoint(
        _dateLabel(record.date),
        departmentCodes.fold<double>(
          0,
          (sum, code) => sum + (record.departments[code]?.laborCost ?? 0),
        ),
      ),
  ];

  List<TrendPoint> departmentCostTrend(String departmentCode) => [
    for (final record in dailyRecords)
      TrendPoint(
        _dateLabel(record.date),
        record.departments[departmentCode]?.laborCost,
      ),
  ];

  double _sumFor(
    Set<String> departmentCodes,
    double Function(DepartmentLaborDay) value,
  ) => dailyRecords.fold<double>(
    0,
    (total, record) =>
        total +
        departmentCodes.fold<double>(0, (subtotal, code) {
          final department = record.departments[code];
          return subtotal + (department == null ? 0 : value(department));
        }),
  );

  static String _dateLabel(DateTime date) => '${date.month}/${date.day}';
}

class Metric {
  const Metric({
    required this.label,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
    this.caption,
  });

  final String label;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;
  final String? caption;
}

class TrendPoint {
  const TrendPoint(this.label, this.value);

  final String label;
  final double? value;
}

class ExpenseItem {
  const ExpenseItem(this.category, this.actual, this.budget, this.color);

  final String category;
  final double actual;
  final double budget;
  final Color color;
}

class DashboardData {
  const DashboardData({
    required this.range,
    required this.dailyRecords,
    required this.metrics,
    required this.censusTrend,
    required this.laborTrend,
    required this.expenseTrend,
    required this.expenses,
    required this.missingDates,
  });

  final DashboardDateRange range;
  final List<DailyDashboardRecord> dailyRecords;
  final List<Metric> metrics;
  final List<TrendPoint> censusTrend;
  final List<TrendPoint> laborTrend;
  final List<TrendPoint> expenseTrend;
  final List<ExpenseItem> expenses;
  final List<DateTime> missingDates;

  int get expectedDayCount => range.dayCount;
  int get reportedDayCount => dailyRecords.length;

  List<DateTime> get calendarDates => range.dates;

  List<String> get bedIds => dailyRecords.isEmpty
      ? const []
      : dailyRecords.first.bedOccupancyHours.keys.toList();

  List<EmployeeLaborDetail> get employees => dailyRecords.isEmpty
      ? const []
      : dailyRecords.first.employeeLabor.values.toList();

  double get averageCensus => dailyRecords.isEmpty
      ? 0
      : dailyRecords.fold<double>(0, (sum, item) => sum + item.census) /
            dailyRecords.length;

  double get totalLaborHours =>
      dailyRecords.fold<double>(0, (sum, item) => sum + item.laborHours);

  double get totalOvertimeHours =>
      dailyRecords.fold<double>(0, (sum, item) => sum + item.overtimeHours);

  double get totalLaborCost =>
      dailyRecords.fold<double>(0, (sum, item) => sum + item.laborCost);

  double get totalExpense =>
      dailyRecords.fold<double>(0, (sum, item) => sum + item.totalExpense);
}
