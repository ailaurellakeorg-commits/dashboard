import 'package:flutter/material.dart';
import 'package:scrollable_clean_calendar/controllers/clean_calendar_controller.dart';
import 'package:scrollable_clean_calendar/scrollable_clean_calendar.dart';
import 'package:scrollable_clean_calendar/utils/enums.dart';

import '../../config/app_theme.dart';
import '../../models/dashboard_models.dart';
import '../../utils/date_formatters.dart';

Future<DashboardDateRange?> showDashboardDateRangePicker({
  required BuildContext context,
  required DashboardDateRange selectedRange,
  required DashboardDateRange availableRange,
}) => showDialog<DashboardDateRange>(
  context: context,
  builder: (_) => _DashboardDateRangeDialog(
    selectedRange: selectedRange,
    availableRange: availableRange,
  ),
);

class _DashboardDateRangeDialog extends StatefulWidget {
  const _DashboardDateRangeDialog({
    required this.selectedRange,
    required this.availableRange,
  });

  final DashboardDateRange selectedRange;
  final DashboardDateRange availableRange;

  @override
  State<_DashboardDateRangeDialog> createState() =>
      _DashboardDateRangeDialogState();
}

class _DashboardDateRangeDialogState extends State<_DashboardDateRangeDialog> {
  late final CleanCalendarController _controller;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.selectedRange.start;
    _end = widget.selectedRange.end;
    _controller = CleanCalendarController(
      minDate: widget.availableRange.start,
      maxDate: widget.availableRange.end,
      initialDateSelected: _start,
      endDateSelected: _end,
      initialFocusDate: _start,
      rangeMode: true,
      onRangeSelected: (start, end) => setState(() {
        _start = start;
        _end = end;
      }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectMonth(DateTime month) {
    final fullMonth = DashboardDateRange.month(month.year, month.month);
    final available = widget.availableRange;
    final range = DashboardDateRange(
      start: fullMonth.start.isBefore(available.start)
          ? available.start
          : fullMonth.start,
      end: fullMonth.end.isAfter(available.end) ? available.end : fullMonth.end,
    );
    _controller
      ..clearSelectedDates()
      ..onDayClick(range.start)
      ..onDayClick(range.end);
    _controller.scrollToMonth(
      date: range.start,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.availableRange;
    final months = <DateTime>[
      for (
        var month = DateTime(available.start.year, available.start.month);
        !month.isAfter(available.end);
        month = DateTime(month.year, month.month + 1)
      )
        month,
    ];
    final height = (MediaQuery.sizeOf(context).height * .82).clamp(
      500.0,
      760.0,
    );
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose date range',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _start == null
                                ? 'Select a start date'
                                : formatDateRange(_start!, _end ?? _start!),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final month in months)
                        ActionChip(
                          label: Text(
                            available.start.year == available.end.year
                                ? monthNames[month.month - 1]
                                : '${monthNames[month.month - 1]} ${month.year}',
                          ),
                          onPressed: () => _selectMonth(month),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: AppTheme.line),
              Expanded(
                child: ClipRect(
                  child: ScrollableCleanCalendar(
                    calendarController: _controller,
                    layout: Layout.BEAUTY,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                    daySelectedBackgroundColor: AppTheme.teal,
                    daySelectedBackgroundColorBetween: AppTheme.mint,
                    dayRadius: 8,
                    monthTextStyle: Theme.of(context).textTheme.titleLarge,
                    weekdayTextStyle: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: AppTheme.muted),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppTheme.line),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _start == null
                          ? null
                          : () => Navigator.pop(
                              context,
                              DashboardDateRange(
                                start: _start!,
                                end: _end ?? _start!,
                              ),
                            ),
                      child: const Text('Apply range'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
