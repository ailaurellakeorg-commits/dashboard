import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laurel_lake_dashboard/main.dart';
import 'package:laurel_lake_dashboard/repositories/dashboard_repository.dart';
import 'package:scrollable_clean_calendar/scrollable_clean_calendar.dart';

void main() {
  testWidgets('renders the executive overview', (tester) async {
    await tester.pumpWidget(
      LaurelLakeDashboardApp(
        repository: DemoDashboardRepository(now: () => DateTime(2026, 9, 30)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Executive overview'), findsOneWidget);
    expect(find.text('Average census'), findsOneWidget);
    expect(find.text('Expense by department'), findsOneWidget);
    expect(find.text('2 days are missing source data'), findsOneWidget);

    await tester.tap(find.text('Census'));
    await tester.pumpAndSettle();
    expect(find.text('Census by day'), findsOneWidget);
    expect(find.text('Bed occupancy detail'), findsOneWidget);
    expect(find.text('Facility1-Nursing-Floor1-Room1-Bed1'), findsOneWidget);

    await tester.tap(find.text('Labor'));
    await tester.pumpAndSettle();
    expect(find.text('Labor cost by day'), findsOneWidget);
    expect(find.text('Employee labor detail'), findsOneWidget);
    expect(find.text('Avery Brooks'), findsOneWidget);
  });

  testWidgets('October shortcut selects current month through today', (
    tester,
  ) async {
    await tester.pumpWidget(
      LaurelLakeDashboardApp(
        repository: DemoDashboardRepository(now: () => DateTime(2026, 10, 7)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('October 1–7, 2026'), findsOneWidget);
    await tester.tap(find.text('October 1–7, 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'September'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'October'));
    await tester.pumpAndSettle();
    final calendar = tester.widget<ScrollableCleanCalendar>(
      find.byType(ScrollableCleanCalendar),
    );
    expect(calendar.calendarController.maxDate, DateTime(2026, 10, 7));
    expect(calendar.calendarController.rangeMinDate, DateTime(2026, 10));
    expect(calendar.calendarController.rangeMaxDate, DateTime(2026, 10, 7));
    await tester.tap(find.text('Apply range'));
    await tester.pumpAndSettle();
    expect(find.text('October 1–7, 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
