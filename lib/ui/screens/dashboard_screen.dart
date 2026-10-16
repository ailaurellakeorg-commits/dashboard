import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../config/app_theme.dart';
import '../../models/dashboard_models.dart';
import '../../utils/date_formatters.dart';
import 'dashboard/bloc/dashboard_bloc.dart';
import 'dashboard/bloc/dashboard_event.dart';
import 'dashboard/bloc/dashboard_state.dart';
import '../widgets/app_card.dart';
import '../widgets/dashboard_date_range_picker.dart';
import '../widgets/detail_matrices.dart';
import '../widgets/trend_chart.dart';
import '../../repositories/labor_directory_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  var _section = 0;

  Future<void> _selectRange(
    BuildContext context,
    DashboardDateRange selectedRange,
  ) async {
    final bloc = context.read<DashboardBloc>();
    final range = await showDashboardDateRangePicker(
      context: context,
      selectedRange: selectedRange,
      availableRange: bloc.repository.availableRange,
    );
    if (range != null && context.mounted) {
      bloc.add(DashboardDateRangeChanged(range));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardInitial || state is DashboardLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DashboardFailure) {
          return _DashboardError(
            message: state.message,
            onRetry: () => context.read<DashboardBloc>().add(
              const DashboardRefreshRequested(),
            ),
          );
        }
        final loadedState = state as DashboardLoaded;
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!compact)
                  _Sidebar(
                    selected: _section,
                    onSelect: (value) => setState(() => _section = value),
                  ),
                Expanded(
                  child: _DashboardContent(
                    section: _section,
                    data: loadedState.data,
                    onSelectRange: () =>
                        _selectRange(context, loadedState.range),
                    onRefresh: () => context.read<DashboardBloc>().add(
                      const DashboardRefreshRequested(),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ),
    bottomNavigationBar: LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 900
          ? NavigationBar(
              selectedIndex: _section,
              onDestinationSelected: (value) =>
                  setState(() => _section = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Overview',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  label: 'Census',
                ),
                NavigationDestination(
                  icon: Icon(Icons.schedule_outlined),
                  label: 'Labor',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: 'Expense',
                ),
              ],
            )
          : const SizedBox.shrink(),
    ),
  );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  static const _items = [
    (Icons.grid_view_rounded, 'Overview'),
    (Icons.groups_outlined, 'Census'),
    (Icons.schedule_outlined, 'Labor'),
    (Icons.receipt_long_outlined, 'Expense'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    width: 244,
    color: AppTheme.navy,
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LAUREL LAKE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Executive Dashboard',
                style: TextStyle(color: Color(0xFFB9D3CE), fontSize: 12),
              ),
            ],
          ),
        ),
        ..._items.indexed.map((entry) {
          final (index, item) = entry;
          final active = selected == index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: active ? const Color(0xFF24525A) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => onSelect(index),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.$1,
                        color: active ? Colors.white : const Color(0xFFA8C0BC),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.$2,
                        style: TextStyle(
                          color: active
                              ? Colors.white
                              : const Color(0xFFA8C0BC),
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        const Divider(color: Color(0xFF315860)),
        const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Aggregate facility data only\nRefreshed automatically',
            style: TextStyle(
              color: Color(0xFFA8C0BC),
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: AppCard(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 34, color: AppTheme.red),
            const SizedBox(height: 14),
            Text(
              'Dashboard unavailable',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.section,
    required this.data,
    required this.onSelectRange,
    required this.onRefresh,
  });

  final int section;
  final DashboardData data;
  final VoidCallback onSelectRange;
  final VoidCallback onRefresh;

  static const _titles = [
    (
      'Executive overview',
      'A board-level view of census, labor, and expense performance.',
    ),
    ('Census', 'Occupancy and resident census, shown day by day.'),
    (
      'Labor',
      'Worked hours, overtime, and labor cost for the selected period.',
    ),
    ('Expense', 'Department expense performance against the period budget.'),
  ];

  @override
  Widget build(BuildContext context) {
    final title = _titles[section];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  title: title.$1,
                  subtitle: title.$2,
                  range: data.range,
                  onSelectRange: onSelectRange,
                  onRefresh: onRefresh,
                ),
                const SizedBox(height: 28),
                if (data.missingDates.isNotEmpty) ...[
                  _MissingDataBanner(data: data),
                  const SizedBox(height: 20),
                ],
                switch (section) {
                  1 => _CensusTab(data: data),
                  2 => _LaborTab(data: data),
                  3 => _ExpenseTab(data: data),
                  _ => _OverviewTab(data: data),
                },
                const SizedBox(height: 22),
                const _DataNote(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.range,
    required this.onSelectRange,
    required this.onRefresh,
  });

  final String title;
  final String subtitle;
  final DashboardDateRange range;
  final VoidCallback onSelectRange;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    runSpacing: 16,
    spacing: 20,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
          ),
          OutlinedButton.icon(
            onPressed: onSelectRange,
            icon: const Icon(Icons.calendar_month_outlined, size: 19),
            label: Text(formatDateRange(range.start, range.end)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.ink,
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppTheme.line),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _MissingDataBanner extends StatelessWidget {
  const _MissingDataBanner({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final dates = data.missingDates.map(formatShortDate).join(', ');
    final count = data.missingDates.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.red.withValues(alpha: .08),
        border: Border.all(color: AppTheme.red.withValues(alpha: .24)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_outlined, color: AppTheme.red),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${count == 1 ? 'day is' : 'days are'} missing source data',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: AppTheme.red),
                ),
                const SizedBox(height: 3),
                Text(
                  '$dates. Totals and averages exclude these days; matrices and charts mark them as missing.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _MetricGrid(metrics: data.metrics),
      const SizedBox(height: 24),
      _ResponsivePair(
        first: _TrendCard(
          title: 'Daily census',
          value: data.averageCensus.toStringAsFixed(1),
          detail: 'Average daily census',
          points: data.censusTrend,
          color: AppTheme.teal,
          axisFormat: TrendAxisFormat.number,
        ),
        second: _TrendCard(
          title: 'Daily labor cost',
          value: formatCurrency(data.totalLaborCost),
          detail: 'Selected period total',
          points: data.laborTrend,
          color: AppTheme.orange,
          axisFormat: TrendAxisFormat.currency,
        ),
      ),
      const SizedBox(height: 24),
      _ExpenseCard(expenses: data.expenses),
    ],
  );
}

class _CensusTab extends StatelessWidget {
  const _CensusTab({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _MetricGrid(metrics: data.metrics.take(2).toList()),
      const SizedBox(height: 24),
      _TrendCard(
        title: 'Census by day',
        value: data.averageCensus.toStringAsFixed(1),
        detail:
            'Average across ${data.reportedDayCount}/${data.expectedDayCount} reported days',
        points: data.censusTrend,
        color: AppTheme.teal,
        axisFormat: TrendAxisFormat.number,
      ),
      const SizedBox(height: 24),
      BedOccupancyMatrix(data: data),
    ],
  );
}

class _LaborTab extends StatefulWidget {
  const _LaborTab({required this.data});

  final DashboardData data;

  @override
  State<_LaborTab> createState() => _LaborTabState();
}

class _LaborTabState extends State<_LaborTab> {
  late Future<List<LaborDepartment>> _departments;
  final Set<String> _selectedDepartmentCodes = {};

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  void _loadDepartments() {
    _departments = context.read<LaborDirectoryRepository>().loadDepartments();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<LaborDepartment>>(
    future: _departments,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const AppCard(
          child: SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      if (snapshot.hasError) {
        return AppCard(
          child: Row(
            children: [
              const Expanded(
                child: Text('Could not load departments and employees.'),
              ),
              IconButton(
                tooltip: 'Retry loading employees',
                onPressed: () => setState(_loadDepartments),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        );
      }

      final departments = snapshot.data ?? const <LaborDepartment>[];
      return Column(
        children: [
          const _LaborMetricsUnavailable(),
          const SizedBox(height: 20),
          _LaborChartUnavailable(
            departments: departments,
            selectedDepartmentCodes: _selectedDepartmentCodes,
            onToggleAll: () => setState(() {
              if (_selectedDepartmentCodes.length == departments.length) {
                _selectedDepartmentCodes.clear();
              } else {
                _selectedDepartmentCodes
                  ..clear()
                  ..addAll(departments.map((department) => department.code));
              }
            }),
          ),
          const SizedBox(height: 20),
          EmployeeLaborMatrix(
            data: widget.data,
            departments: departments,
            selectedDepartmentCodes: _selectedDepartmentCodes,
            onDepartmentSelectionChanged: (departmentCode, selected) {
              setState(() {
                if (selected) {
                  _selectedDepartmentCodes.add(departmentCode);
                } else {
                  _selectedDepartmentCodes.remove(departmentCode);
                }
              });
            },
          ),
        ],
      );
    },
  );
}

class _LaborMetricsUnavailable extends StatelessWidget {
  const _LaborMetricsUnavailable();

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Labor metrics unavailable',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'No dated timekeeping or payroll amounts are available. '
          'Labor hours, overtime, and costs are not calculated.',
        ),
        const SizedBox(height: 14),
        const Wrap(
          spacing: 28,
          runSpacing: 12,
          children: [
            _UnavailableMetric(label: 'Labor cost'),
            _UnavailableMetric(label: 'Worked hours'),
            _UnavailableMetric(label: 'Overtime hours'),
          ],
        ),
      ],
    ),
  );
}

class _UnavailableMetric extends StatelessWidget {
  const _UnavailableMetric({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 150,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        const Text('—', style: TextStyle(fontSize: 24, color: AppTheme.muted)),
      ],
    ),
  );
}

class _LaborChartUnavailable extends StatelessWidget {
  const _LaborChartUnavailable({
    required this.departments,
    required this.selectedDepartmentCodes,
    required this.onToggleAll,
  });

  final List<LaborDepartment> departments;
  final Set<String> selectedDepartmentCodes;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final selected = departments
        .where(
          (department) => selectedDepartmentCodes.contains(department.code),
        )
        .toList();
    final allSelected =
        departments.isNotEmpty &&
        selectedDepartmentCodes.length == departments.length;
    final allHidden = selectedDepartmentCodes.isEmpty;
    final allValue = allSelected
        ? true
        : allHidden
        ? false
        : null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily labor cost',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              const _LaborLegendItem(label: 'Total', color: AppTheme.orange),
              for (final department in selected)
                _LaborLegendItem(
                  label: department.name,
                  color: _departmentColor(departments.indexOf(department)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.canvas,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.line),
              ),
              child: const Center(
                child: Text(
                  'Dated labor costs are unavailable; no lines can be plotted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.muted),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Checkbox(
                key: const ValueKey('toggle-all-departments'),
                visualDensity: VisualDensity.compact,
                tristate: true,
                value: allValue,
                onChanged: departments.isEmpty ? null : (_) => onToggleAll(),
              ),
              const Text('Show all departments'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LaborLegendItem extends StatelessWidget {
  const _LaborLegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 3,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.labelMedium),
    ],
  );
}

Color _departmentColor(int index) =>
    HSLColor.fromAHSL(1, (index * 137.508) % 360, .62, .42).toColor();

class _ExpenseTab extends StatelessWidget {
  const _ExpenseTab({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final budget = data.expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.budget,
    );
    final variance = data.totalExpense - budget;
    final metrics = [
      Metric(
        label: 'Total expense',
        value: formatCurrency(data.totalExpense),
        change: variance <= 0
            ? '${formatCurrency(variance.abs())} under budget'
            : '${formatCurrency(variance)} over budget',
        isPositive: variance <= 0,
        icon: Icons.receipt_long_outlined,
        color: AppTheme.orange,
        caption:
            '${data.reportedDayCount}/${data.expectedDayCount} days reported',
      ),
      Metric(
        label: 'Daily average',
        value: formatCurrency(data.totalExpense / data.dailyRecords.length),
        change: 'Across all departments',
        isPositive: true,
        icon: Icons.calendar_view_day_outlined,
        color: AppTheme.teal,
        caption: 'facility-level total',
      ),
    ];
    return Column(
      children: [
        _MetricGrid(metrics: metrics),
        const SizedBox(height: 24),
        _TrendCard(
          title: 'Expense by day',
          value: formatCurrency(data.totalExpense),
          detail: 'Selected period total',
          points: data.expenseTrend,
          color: const Color(0xFF3267A8),
          axisFormat: TrendAxisFormat.currency,
        ),
        const SizedBox(height: 24),
        _ExpenseCard(expenses: data.expenses),
        const SizedBox(height: 24),
        _DailyTable(
          title: 'Daily expense detail',
          headers: const [
            'DATE',
            'NURSING',
            'DIETARY',
            'HOUSEKEEPING',
            'THERAPY',
          ],
          records: data.dailyRecords,
          values: (record) => [
            formatCurrency(record.nursingExpense),
            formatCurrency(record.dietaryExpense),
            formatCurrency(record.housekeepingExpense),
            formatCurrency(record.therapyExpense),
          ],
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<Metric> metrics;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 1100
          ? metrics.length.clamp(1, 4)
          : constraints.maxWidth >= 650
          ? 2
          : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: metrics.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: columns == 1
              ? 3.0
              : columns == 2 && constraints.maxWidth >= 1100
              ? 3.35
              : 1.65,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemBuilder: (context, index) => _MetricCard(metric: metrics[index]),
      );
    },
  );
}

class _ResponsivePair extends StatelessWidget {
  const _ResponsivePair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth < 900
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 20), second],
          )
        : Row(
            children: [
              Expanded(child: first),
              const SizedBox(width: 20),
              Expanded(child: second),
            ],
          ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final Metric metric;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              metric.label,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: AppTheme.muted),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: metric.color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(metric.icon, color: metric.color, size: 20),
            ),
          ],
        ),
        const Spacer(),
        Text(
          metric.value,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          metric.caption ?? '',
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: AppTheme.muted),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              metric.isPositive ? Icons.trending_up : Icons.trending_down,
              size: 16,
              color: metric.isPositive ? AppTheme.teal : AppTheme.red,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                metric.change,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: metric.isPositive ? AppTheme.teal : AppTheme.red,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.points,
    required this.color,
    required this.axisFormat,
  });

  final String title;
  final String value;
  final String detail;
  final List<TrendPoint> points;
  final Color color;
  final TrendAxisFormat axisFormat;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 8,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                detail,
                style: const TextStyle(fontSize: 13, color: AppTheme.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TrendChart(points: points, color: color, axisFormat: axisFormat),
      ],
    ),
  );
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({required this.expenses});

  final List<ExpenseItem> expenses;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Expense by department',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Actual vs. budget',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: AppTheme.muted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _ExpenseHeadings(),
        const Divider(height: 16, color: AppTheme.line),
        ...expenses.map((expense) => _ExpenseRow(item: expense)),
      ],
    ),
  );
}

class _ExpenseHeadings extends StatelessWidget {
  const _ExpenseHeadings();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(flex: 3, child: _TableHeading('DEPARTMENT')),
      Expanded(child: _TableHeading('ACTUAL', align: TextAlign.end)),
      Expanded(child: _TableHeading('BUDGET', align: TextAlign.end)),
    ],
  );
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.item});

  final ExpenseItem item;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                item.category,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: Text(
            formatCurrency(item.actual),
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: item.actual > item.budget ? AppTheme.red : AppTheme.ink,
            ),
          ),
        ),
        Expanded(
          child: Text(
            formatCurrency(item.budget),
            textAlign: TextAlign.end,
            style: const TextStyle(color: AppTheme.muted),
          ),
        ),
      ],
    ),
  );
}

class _DailyTable extends StatelessWidget {
  const _DailyTable({
    required this.title,
    required this.headers,
    required this.records,
    required this.values,
  });

  final String title;
  final List<String> headers;
  final List<DailyDashboardRecord> records;
  final List<String> Function(DailyDashboardRecord record) values;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              Text(
                '${records.length} days',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: AppTheme.muted),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.line),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 660),
            child: IntrinsicWidth(
              child: Column(
                children: [
                  _DailyTableRow(values: headers, heading: true),
                  ...records.reversed.map(
                    (record) => _DailyTableRow(
                      values: [formatShortDate(record.date), ...values(record)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DailyTableRow extends StatelessWidget {
  const _DailyTableRow({required this.values, this.heading = false});

  final List<String> values;
  final bool heading;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppTheme.line)),
    ),
    child: Row(
      children: values.indexed.map((entry) {
        final (index, value) = entry;
        return SizedBox(
          width: index == 0 ? 130 : 132,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: heading
                ? _TableHeading(
                    value,
                    align: index == 0 ? TextAlign.start : TextAlign.end,
                  )
                : Text(
                    value,
                    textAlign: index == 0 ? TextAlign.start : TextAlign.end,
                    style: TextStyle(
                      color: index == 0 ? AppTheme.ink : AppTheme.muted,
                      fontWeight: index == 0
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
          ),
        );
      }).toList(),
    ),
  );
}

class _TableHeading extends StatelessWidget {
  const _TableHeading(this.text, {this.align = TextAlign.start});

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    style: const TextStyle(
      fontSize: 11,
      color: AppTheme.muted,
      fontWeight: FontWeight.w700,
      letterSpacing: .5,
    ),
  );
}

class _DataNote extends StatelessWidget {
  const _DataNote();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.mint,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.verified_user_outlined, color: AppTheme.teal),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Demo details use synthetic bed and employee identifiers. Confirm role-based access and data-handling requirements before connecting person-level production records.',
            style: TextStyle(color: AppTheme.navy, height: 1.4),
          ),
        ),
      ],
    ),
  );
}
