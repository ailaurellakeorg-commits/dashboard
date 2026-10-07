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

class EmployeeLaborMatrix extends StatelessWidget {
  const EmployeeLaborMatrix({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final recordsByDate = {
      for (final record in data.dailyRecords) _dateKey(record.date): record,
    };
    final dates = data.calendarDates.reversed.toList();
    final employees = data.employees;
    return DetailMatrix(
      matrixId:
          'labor-${data.range.start.toIso8601String()}-${data.range.end.toIso8601String()}',
      title: 'Employee labor detail',
      description:
          '${employees.length} employees · each cell shows worked hours and labor cost',
      rowCount: employees.length,
      columnCount: dates.length,
      leadingColumnWidth: 220,
      dataColumnWidth: 120,
      headerHeight: 72,
      rowHeight: 54,
      cornerBuilder: (_) => const MatrixHeaderCell(
        title: 'EMPLOYEE',
        detail: 'Selected-period total',
        leading: true,
      ),
      rowHeaderBuilder: (context, row) {
        final employee = employees[row];
        final hours = data.dailyRecords.fold<double>(
          0,
          (sum, record) =>
              sum + (record.employeeLabor[employee.employeeId]?.hours ?? 0),
        );
        final cost = data.dailyRecords.fold<double>(
          0,
          (sum, record) =>
              sum + (record.employeeLabor[employee.employeeId]?.cost ?? 0),
        );
        return MatrixHeaderCell(
          title: employee.employeeName,
          detail:
              '${employee.employeeId} · ${employee.role}\n${hours.toStringAsFixed(1)}h · ${formatCurrency(cost)}',
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
              : '${record.laborHours.toStringAsFixed(1)}h\n${formatCurrency(record.laborCost)}',
          missing: record == null,
        );
      },
      cellBuilder: (context, row, column) {
        final employee = employees[row];
        final record = recordsByDate[_dateKey(dates[column])];
        if (record == null) {
          return const MatrixValueCell(primary: 'N/A', missing: true);
        }
        final detail = record.employeeLabor[employee.employeeId]!;
        return MatrixValueCell(
          primary: detail.hours == 0
              ? '—'
              : '${detail.hours.toStringAsFixed(1)}h',
          secondary: detail.hours == 0 ? null : formatCurrency(detail.cost),
          emphasized: detail.hours >= 9.5,
        );
      },
    );
  }
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
