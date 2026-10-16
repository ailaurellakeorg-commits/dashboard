import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../../config/app_theme.dart';
import '../../models/dashboard_models.dart';
import '../../utils/date_formatters.dart';
import 'app_card.dart';

class BedOccupancyMatrix extends StatelessWidget {
  const BedOccupancyMatrix({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final recordsByDate = {
      for (final record in data.dailyRecords) _dateKey(record.date): record,
    };
    final dates = data.calendarDates.reversed.toList();
    final beds = data.bedIds;
    return DetailMatrix(
      matrixId:
          'beds-${data.range.start.toIso8601String()}-${data.range.end.toIso8601String()}',
      title: 'Bed occupancy detail',
      description:
          '${beds.length} beds · each cell shows occupied hours for that day',
      rowCount: beds.length,
      columnCount: dates.length,
      leadingColumnWidth: 250,
      dataColumnWidth: 108,
      headerHeight: 72,
      rowHeight: 48,
      cornerBuilder: (_) => const MatrixHeaderCell(
        title: 'BED',
        detail: 'Selected-period occupancy',
        leading: true,
      ),
      rowHeaderBuilder: (context, row) {
        final bedId = beds[row];
        final hours = data.dailyRecords.fold<double>(
          0,
          (sum, record) => sum + (record.bedOccupancyHours[bedId] ?? 0),
        );
        final days = data.dailyRecords
            .where((record) => (record.bedOccupancyHours[bedId] ?? 0) > 0)
            .length;
        final percent = hours / (data.expectedDayCount * 24) * 100;
        return MatrixHeaderCell(
          title: bedId,
          detail:
              '${hours.toStringAsFixed(0)}h · $days/${data.expectedDayCount} days · ${percent.toStringAsFixed(0)}%',
          leading: true,
        );
      },
      columnHeaderBuilder: (context, column) {
        final date = dates[column];
        final record = recordsByDate[_dateKey(date)];
        return MatrixHeaderCell(
          title: formatShortDate(date),
          detail: record == null
              ? 'No data\nreported'
              : '${record.census} occupied\nbeds',
          missing: record == null,
        );
      },
      cellBuilder: (context, row, column) {
        final record = recordsByDate[_dateKey(dates[column])];
        if (record == null) {
          return const MatrixValueCell(primary: 'N/A', missing: true);
        }
        final hours = record.bedOccupancyHours[beds[row]] ?? 0;
        return MatrixValueCell(
          primary: hours == 0 ? '—' : '${hours.toStringAsFixed(0)}h',
          emphasized: hours == 24,
          partial: hours > 0 && hours < 24,
        );
      },
    );
  }
}

class EmployeeLaborMatrix extends StatefulWidget {
  const EmployeeLaborMatrix({
    super.key,
    required this.data,
    required this.departments,
    required this.analytics,
    required this.selectedDepartmentCodes,
    required this.onDepartmentSelectionChanged,
  });

  final DashboardData data;
  final List<LaborDepartment> departments;
  final LaborAnalyticsData? analytics;
  final Set<String> selectedDepartmentCodes;
  final void Function(String departmentCode, bool selected)
  onDepartmentSelectionChanged;

  @override
  State<EmployeeLaborMatrix> createState() => _EmployeeLaborMatrixState();
}

class _EmployeeLaborMatrixState extends State<EmployeeLaborMatrix> {
  final Set<String> _expandedDepartments = {};

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final analyticsByDate = {
      for (final record
          in widget.analytics?.dailyRecords ??
              const <DailyDepartmentLaborRecord>[])
        _dateKey(record.date): record,
    };
    final dates = data.calendarDates.reversed.toList();
    final visibleRows = <_LaborMatrixRow>[];
    for (final department in widget.departments) {
      visibleRows.add(_LaborMatrixRow.department(department));
      if (_expandedDepartments.contains(department.code)) {
        visibleRows.addAll(
          department.employees.map(
            (employee) => _LaborMatrixRow.employee(department, employee),
          ),
        );
      }
    }
    final employeeCount = widget.departments.fold<int>(
      0,
      (count, department) => count + department.employees.length,
    );

    return DetailMatrix(
      matrixId:
          'labor-${data.range.start.toIso8601String()}-${data.range.end.toIso8601String()}',
      title: 'Employee labor detail',
      description:
          '$employeeCount employees across ${widget.departments.length} departments · '
          '${widget.analytics == null ? 'live employee-day costs unavailable' : 'synthetic demo hours and costs'}',
      rowCount: visibleRows.length,
      columnCount: dates.length,
      leadingColumnWidth: 250,
      dataColumnWidth: 120,
      headerHeight: 72,
      rowHeight: 64,
      cornerBuilder: (_) => const MatrixHeaderCell(
        title: 'DEPARTMENT / EMPLOYEE',
        detail: 'Rates and daily totals',
        leading: true,
      ),
      rowHeaderBuilder: (context, row) {
        final item = visibleRows[row];
        if (item.employee case final employee?) {
          return Padding(
            padding: const EdgeInsets.only(left: 24),
            child: MatrixHeaderCell(
              title: employee.name,
              detail: employee.rateSubtitle,
              leading: true,
            ),
          );
        }

        final department = item.department;
        final expanded = _expandedDepartments.contains(department.code);
        return Row(
          children: [
            Checkbox(
              key: ValueKey('department-toggle-${department.code}'),
              value: widget.selectedDepartmentCodes.contains(department.code),
              onChanged: (selected) => widget.onDepartmentSelectionChanged(
                department.code,
                selected ?? false,
              ),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            IconButton(
              key: ValueKey('expand-department-${department.code}'),
              tooltip: expanded ? 'Collapse department' : 'Expand department',
              onPressed: () => setState(() {
                if (expanded) {
                  _expandedDepartments.remove(department.code);
                } else {
                  _expandedDepartments.add(department.code);
                }
              }),
              icon: Icon(
                expanded ? Icons.expand_more : Icons.chevron_right,
                size: 18,
                color: AppTheme.muted,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 42),
            ),
            Expanded(
              child: MatrixHeaderCell(
                title: department.name,
                detail:
                    '${department.employees.length} employees · ${department.code}',
                leading: true,
              ),
            ),
          ],
        );
      },
      columnHeaderBuilder: (context, column) {
        final date = dates[column];
        final record = analyticsByDate[_dateKey(date)];
        if (widget.analytics == null || record == null) {
          return MatrixHeaderCell(
            title: formatShortDate(date),
            detail: 'Live data\nunavailable',
          );
        }
        final allDepartmentValues = record.departments.values;
        final laborCost = allDepartmentValues.fold<double>(
          0,
          (total, value) => total + value.laborCost,
        );
        final laborHours = allDepartmentValues.fold<double>(
          0,
          (total, value) => total + value.workedHours,
        );
        return MatrixHeaderCell(
          title: formatShortDate(date),
          detail:
              '${laborHours.toStringAsFixed(1)}h\n${formatCurrency(laborCost)}',
        );
      },
      cellBuilder: (context, row, column) {
        final matrixRow = visibleRows[row];
        final dailyRecord = analyticsByDate[_dateKey(dates[column])];
        if (matrixRow.employee == null) {
          final departmentDay =
              dailyRecord?.departments[matrixRow.department.code];
          if (departmentDay == null) return const SizedBox.shrink();
          if (departmentDay.workedHours == 0) {
            return const MatrixValueCell(primary: '—');
          }
          return MatrixValueCell(
            primary: '${departmentDay.workedHours.toStringAsFixed(1)}h',
            secondary: formatCurrency(departmentDay.laborCost),
          );
        }

        final employeeDay = dailyRecord?.employees[matrixRow.employee!.code];
        if (employeeDay == null) return const SizedBox.shrink();
        if (employeeDay.workedHours == 0) {
          return const MatrixValueCell(primary: '—');
        }
        return MatrixValueCell(
          primary: '${employeeDay.workedHours.toStringAsFixed(1)}h',
          secondary: formatCurrency(employeeDay.cost),
          emphasized: employeeDay.overtimeHours > 0,
        );
      },
    );
  }
}

class _LaborMatrixRow {
  const _LaborMatrixRow.department(this.department) : employee = null;

  const _LaborMatrixRow.employee(this.department, this.employee);

  final LaborDepartment department;
  final LaborEmployee? employee;
}

typedef MatrixIndexedBuilder = Widget Function(BuildContext context, int index);
typedef MatrixCellBuilder = Widget Function(
  BuildContext context,
  int row,
  int column,
);

class DetailMatrix extends StatelessWidget {
  const DetailMatrix({
    super.key,
    required this.matrixId,
    required this.title,
    required this.description,
    required this.rowCount,
    required this.columnCount,
    required this.leadingColumnWidth,
    required this.dataColumnWidth,
    required this.headerHeight,
    required this.rowHeight,
    required this.cornerBuilder,
    required this.rowHeaderBuilder,
    required this.columnHeaderBuilder,
    required this.cellBuilder,
  });

  final String matrixId;
  final String title;
  final String description;
  final int rowCount;
  final int columnCount;
  final double leadingColumnWidth;
  final double dataColumnWidth;
  final double headerHeight;
  final double rowHeight;
  final WidgetBuilder cornerBuilder;
  final MatrixIndexedBuilder rowHeaderBuilder;
  final MatrixIndexedBuilder columnHeaderBuilder;
  final MatrixCellBuilder cellBuilder;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 11),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Row(
                children: [
                  Icon(Icons.swap_vert, size: 16, color: AppTheme.muted),
                  SizedBox(width: 6),
                  Text(
                    'Scroll vertically · drag sideways for dates',
                    style: TextStyle(fontSize: 12, color: AppTheme.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.line),
        SizedBox(
          height: 600,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: TableView.builder(
              key: ValueKey(matrixId),
              pinnedRowCount: 1,
              pinnedColumnCount: 1,
              // Lock each gesture to its initially dominant axis. Vertical is
              // the primary reading direction; horizontal movement therefore
              // requires an intentional sideways gesture instead of drifting
              // during normal scrolling.
              diagonalDragBehavior: DiagonalDragBehavior.none,
              rowCount: rowCount + 1,
              columnCount: columnCount + 1,
              rowBuilder: (row) => TableSpan(
                extent: FixedTableSpanExtent(
                  row == 0 ? headerHeight : rowHeight,
                ),
              ),
              columnBuilder: (column) => TableSpan(
                extent: FixedTableSpanExtent(
                  column == 0 ? leadingColumnWidth : dataColumnWidth,
                ),
              ),
              cellBuilder: (context, vicinity) {
                final row = vicinity.row;
                final column = vicinity.column;
                final child = switch ((row, column)) {
                  (0, 0) => cornerBuilder(context),
                  (0, _) => columnHeaderBuilder(context, column - 1),
                  (_, 0) => rowHeaderBuilder(context, row - 1),
                  _ => cellBuilder(context, row - 1, column - 1),
                };
                return TableViewCell(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: row == 0
                          ? AppTheme.mint
                          : column == 0
                          ? AppTheme.canvas
                          : Colors.white,
                      border: const Border(
                        right: BorderSide(color: AppTheme.line),
                        bottom: BorderSide(color: AppTheme.line),
                      ),
                    ),
                    child: child,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}

class MatrixHeaderCell extends StatelessWidget {
  const MatrixHeaderCell({
    super.key,
    required this.title,
    required this.detail,
    this.leading = false,
    this.missing = false,
  });

  final String title;
  final String detail;
  final bool leading;
  final bool missing;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: missing ? AppTheme.red.withValues(alpha: .08) : Colors.transparent,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: leading
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: leading ? TextAlign.start : TextAlign.center,
            style: TextStyle(
              color: missing ? AppTheme.red : AppTheme.ink,
              fontSize: leading ? 12 : 11,
              fontWeight: FontWeight.w700,
              height: 1.18,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: leading ? TextAlign.start : TextAlign.center,
            style: TextStyle(
              color: missing ? AppTheme.red : AppTheme.muted,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ],
      ),
    ),
  );
}

class MatrixValueCell extends StatelessWidget {
  const MatrixValueCell({
    super.key,
    required this.primary,
    this.secondary,
    this.emphasized = false,
    this.partial = false,
    this.missing = false,
  });

  final String primary;
  final String? secondary;
  final bool emphasized;
  final bool partial;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    final color = missing
        ? AppTheme.red
        : emphasized
        ? AppTheme.teal
        : partial
        ? AppTheme.orange
        : AppTheme.muted;
    return ColoredBox(
      color: missing
          ? AppTheme.red.withValues(alpha: .08)
          : emphasized
          ? AppTheme.mint.withValues(alpha: .55)
          : partial
          ? AppTheme.orange.withValues(alpha: .08)
          : Colors.transparent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              primary,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: emphasized || partial
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
            if (secondary != null) ...[
              const SizedBox(height: 1),
              Text(
                secondary!,
                style: const TextStyle(color: AppTheme.muted, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
