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
