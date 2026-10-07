import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/dashboard_models.dart';

abstract interface class DashboardRepository {
  DashboardDateRange get availableRange;

  Future<DashboardData> loadDashboard({required DashboardDateRange range});
}

/// Deterministic facility-level mock data for every day from July through
/// September 2026. Replace this repository when the reporting API is ready.
class DemoDashboardRepository implements DashboardRepository {
  DemoDashboardRepository() : _records = _generateRecords();

  static final DashboardDateRange _availableRange = DashboardDateRange(
    start: DateTime(2026, 7),
    end: DateTime(2026, 9, 30),
  );

  final List<DailyDashboardRecord> _records;

  static final Set<String> _missingDateKeys = {
    _dateKey(DateTime(2026, 7, 9)),
    _dateKey(DateTime(2026, 8, 17)),
    _dateKey(DateTime(2026, 9, 10)),
    _dateKey(DateTime(2026, 9, 24)),
  };

  @override
  DashboardDateRange get availableRange => _availableRange;

  @override
  Future<DashboardData> loadDashboard({
    required DashboardDateRange range,
  }) async {
    final records = _records
        .where((record) => range.contains(record.date))
        .toList();
    if (records.isEmpty) {
      throw StateError('No dashboard data exists for the selected range.');
    }
    final recordsByDate = {
      for (final record in records) _dateKey(record.date): record,
    };
    final selectedDates = List.generate(
      range.dayCount,
      (index) => range.start.add(Duration(days: index)),
    );
    final missingDates = selectedDates
        .where((date) => !recordsByDate.containsKey(_dateKey(date)))
        .toList();

    final previousEnd = range.start.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(
      Duration(days: range.dayCount - 1),
    );
    final previousRecords = _records
        .where(
          (record) =>
              !record.date.isBefore(previousStart) &&
              !record.date.isAfter(previousEnd),
        )
        .toList();

    final census = _average(records.map((item) => item.census.toDouble()));
    final previousCensus = _average(
      previousRecords.map((item) => item.census.toDouble()),
    );
    final laborCost = _sum(records.map((item) => item.laborCost));
    final previousLaborCost = _sum(
      previousRecords.map((item) => item.laborCost),
    );
    final overtime = _sum(records.map((item) => item.overtimeHours));
    final previousOvertime = _sum(
      previousRecords.map((item) => item.overtimeHours),
    );

    return DashboardData(
      range: range,
      dailyRecords: records,
      metrics: [
        Metric(
          label: 'Average census',
          value: census.toStringAsFixed(1),
          change: _comparison(census, previousCensus),
          isPositive: census >= previousCensus,
          icon: Icons.groups_outlined,
          color: AppTheme.teal,
          caption:
              '160 beds · ${records.length}/${range.dayCount} days reported',
        ),
        Metric(
          label: 'Occupancy',
          value: '${(census / 160 * 100).toStringAsFixed(1)}%',
          change: previousCensus == 0
              ? 'No prior-period data'
              : '${((census - previousCensus) / 160 * 100).abs().toStringAsFixed(1)} pts vs prior',
          isPositive: census >= previousCensus,
          icon: Icons.home_work_outlined,
          color: const Color(0xFF3267A8),
          caption: 'all levels of care',
        ),
        Metric(
          label: 'Labor cost',
          value: _compactCurrency(laborCost),
          change: _comparison(laborCost, previousLaborCost),
          isPositive: laborCost <= previousLaborCost && previousLaborCost > 0,
          icon: Icons.payments_outlined,
          color: AppTheme.orange,
          caption: '${records.length}/${range.dayCount} days reported',
        ),
        Metric(
          label: 'Overtime hours',
          value: overtime.toStringAsFixed(0),
          change: _comparison(overtime, previousOvertime),
          isPositive: overtime <= previousOvertime && previousOvertime > 0,
          icon: Icons.timer_outlined,
          color: AppTheme.red,
          caption: 'worked hours only',
        ),
      ],
      censusTrend: selectedDates.map((date) {
        final record = recordsByDate[_dateKey(date)];
        return TrendPoint(_dateLabel(date), record?.census.toDouble());
      }).toList(),
      laborTrend: selectedDates.map((date) {
        final record = recordsByDate[_dateKey(date)];
        return TrendPoint(_dateLabel(date), record?.laborCost);
      }).toList(),
      expenseTrend: selectedDates.map((date) {
        final record = recordsByDate[_dateKey(date)];
        return TrendPoint(_dateLabel(date), record?.totalExpense);
      }).toList(),
      expenses: [
        ExpenseItem(
          'Nursing',
          _sum(records.map((item) => item.nursingExpense)),
          range.dayCount * 4100,
          AppTheme.red,
        ),
        ExpenseItem(
          'Dietary',
          _sum(records.map((item) => item.dietaryExpense)),
          range.dayCount * 1050,
          AppTheme.teal,
        ),
        ExpenseItem(
          'Housekeeping',
          _sum(records.map((item) => item.housekeepingExpense)),
          range.dayCount * 800,
          AppTheme.orange,
        ),
        ExpenseItem(
          'Therapy',
          _sum(records.map((item) => item.therapyExpense)),
          range.dayCount * 620,
          const Color(0xFF3267A8),
        ),
      ],
      missingDates: missingDates,
    );
  }

  static List<DailyDashboardRecord> _generateRecords() {
    final records = <DailyDashboardRecord>[];
    final first = DateTime(2026, 7);
    final last = DateTime(2026, 9, 30);
    final bedIds = _generateBedIds();
    final employees = _generateEmployees();

    for (
      var date = first;
      !date.isAfter(last);
      date = date.add(const Duration(days: 1))
    ) {
      if (_missingDateKeys.contains(_dateKey(date))) continue;
      final index = date.difference(first).inDays;
      final weekend = date.weekday >= DateTime.saturday;
      final wave = math.sin(index * .43);
      final secondaryWave = math.cos(index * .19);
      final monthlyLift = (date.month - 7) * 3;
      final census = (134 + monthlyLift + wave * 4 + secondaryWave * 2)
          .round()
          .clamp(126, 153);
      final laborHours = 530 + census * .92 + wave * 18 + (weekend ? 24 : 0);
      final overtimeHours = math.max(
        4.0,
        8 + wave * 3 + (weekend ? 5.5 : 0) + monthlyLift * .35,
      );
      final laborCost = laborHours * 35.4 + overtimeHours * 18.2;
      final rotation = index * 17 % bedIds.length;
      final bedOccupancyHours = <String, double>{};
      for (var bedIndex = 0; bedIndex < bedIds.length; bedIndex++) {
        final rank = (bedIndex - rotation + bedIds.length) % bedIds.length;
        final occupied = rank < census;
        final transitionHours = 8 + ((bedIndex + index) % 15).toDouble();
        bedOccupancyHours[bedIds[bedIndex]] = !occupied
            ? 0
            : rank >= census - 3
            ? transitionHours
            : 24;
      }

      final rawEmployeeHours = <double>[];
      for (
        var employeeIndex = 0;
        employeeIndex < employees.length;
        employeeIndex++
      ) {
        final scheduled = (employeeIndex * 7 + index * 3) % 13 < 10;
        rawEmployeeHours.add(
          scheduled
              ? 7.2 + ((employeeIndex + index) % 5) * .55 + (weekend ? .4 : 0)
              : 0,
        );
      }
      final hoursScale = laborHours / _sum(rawEmployeeHours);
      final scaledHours = rawEmployeeHours
          .map((hours) => hours * hoursScale)
          .toList();
      final unscaledCost = List.generate(
        employees.length,
        (employeeIndex) =>
            scaledHours[employeeIndex] * employees[employeeIndex].hourlyRate,
      );
      final costScale = laborCost / _sum(unscaledCost);
      final employeeLabor = <String, EmployeeLaborDetail>{};
      for (
        var employeeIndex = 0;
        employeeIndex < employees.length;
        employeeIndex++
      ) {
        final employee = employees[employeeIndex];
        employeeLabor[employee.id] = EmployeeLaborDetail(
          employeeId: employee.id,
          employeeName: employee.name,
          role: employee.role,
          hours: scaledHours[employeeIndex],
          cost: unscaledCost[employeeIndex] * costScale,
        );
      }

      records.add(
        DailyDashboardRecord(
          date: date,
          census: census,
          laborHours: laborHours,
          overtimeHours: overtimeHours,
          laborCost: laborCost,
          nursingExpense: 3850 + census * 2.1 + wave * 135,
          dietaryExpense: 870 + census * 1.18 + secondaryWave * 45,
          housekeepingExpense: 680 + census * .72 + wave * 32,
          therapyExpense: 505 + census * .76 + secondaryWave * 55,
          bedOccupancyHours: bedOccupancyHours,
          employeeLabor: employeeLabor,
        ),
      );
    }
    return records;
  }

  static List<String> _generateBedIds() {
    const units = ['Nursing', 'AssistedLiving', 'MemoryCare', 'Rehab'];
    return List.generate(160, (index) {
      final unit = units[index ~/ 40];
      final floor = (index % 40) ~/ 10 + 1;
      final room = (index % 10) ~/ 2 + 1 + (floor - 1) * 5;
      final bed = index % 2 + 1;
      return 'Facility1-$unit-Floor$floor-Room$room-Bed$bed';
    });
  }

  static List<_EmployeeDefinition> _generateEmployees() {
    const firstNames = [
      'Avery',
      'Jordan',
      'Morgan',
      'Taylor',
      'Riley',
      'Casey',
      'Cameron',
      'Drew',
      'Parker',
      'Quinn',
    ];
    const lastNames = [
      'Brooks',
      'Carter',
      'Diaz',
      'Evans',
      'Foster',
      'Grant',
      'Hayes',
      'Irwin',
    ];
    const roles = [
      ('RN', 44.0),
      ('LPN', 35.0),
      ('CNA', 24.0),
      ('Medication Aide', 27.0),
      ('Dietary Aide', 21.0),
      ('Housekeeper', 20.0),
      ('Therapist', 48.0),
      ('Activities Aide', 22.0),
    ];
    return List.generate(80, (index) {
      final role = roles[index % roles.length];
      return _EmployeeDefinition(
        id: 'EMP-${(index + 1).toString().padLeft(3, '0')}',
        name:
            '${firstNames[index % firstNames.length]} ${lastNames[index ~/ firstNames.length]}',
        role: role.$1,
        hourlyRate: role.$2,
      );
    });
  }

  static double _sum(Iterable<double> values) =>
      values.fold<double>(0, (sum, value) => sum + value);

  static double _average(Iterable<double> values) {
    final list = values.toList();
    return list.isEmpty ? 0 : _sum(list) / list.length;
  }

  static String _comparison(double current, double previous) {
    if (previous == 0) return 'No prior-period data';
    final difference = (current - previous) / previous * 100;
    final direction = difference >= 0 ? 'up' : 'down';
    return '${difference.abs().toStringAsFixed(1)}% $direction vs prior';
  }

  static String _compactCurrency(double value) => value >= 1000
      ? '\$${(value / 1000).toStringAsFixed(1)}K'
      : '\$${value.toStringAsFixed(0)}';

  static String _dateLabel(DateTime date) =>
      '${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} ${date.day}';

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _EmployeeDefinition {
  const _EmployeeDefinition({
    required this.id,
    required this.name,
    required this.role,
    required this.hourlyRate,
  });

  final String id;
  final String name;
  final String role;
  final double hourlyRate;
}
