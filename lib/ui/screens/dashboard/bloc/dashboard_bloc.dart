import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/dashboard_models.dart';
import '../../../../repositories/dashboard_repository.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({required this.repository}) : super(DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoadRequested);
    on<DashboardRefreshRequested>(_onRefreshRequested);
    on<DashboardDateRangeChanged>(_onDateRangeChanged);
  }

  final DashboardRepository repository;

  Future<void> _onLoadRequested(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) => _load(
    range: event.range ?? DashboardDateRange.month(2026, 9),
    emit: emit,
  );

  Future<void> _onRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) => _load(range: state.range, emit: emit);

  Future<void> _onDateRangeChanged(
    DashboardDateRangeChanged event,
    Emitter<DashboardState> emit,
  ) => _load(range: event.range, emit: emit);

  Future<void> _load({
    required DashboardDateRange range,
    required Emitter<DashboardState> emit,
  }) async {
    emit(DashboardLoading(range: range));
    try {
      final data = await repository.loadDashboard(range: range);
      emit(DashboardLoaded(range: range, data: data));
    } catch (_) {
      emit(
        DashboardFailure(
          range: range,
          message: 'The dashboard could not be loaded. Please try again.',
        ),
      );
    }
  }
}
