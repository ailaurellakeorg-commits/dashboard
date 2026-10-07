import 'package:flutter_test/flutter_test.dart';
import 'package:laurel_lake_dashboard/main.dart';

void main() {
  testWidgets('renders the executive overview', (tester) async {
    await tester.pumpWidget(const LaurelLakeDashboardApp());
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
}
