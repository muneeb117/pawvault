import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/models/record_model.dart';
import '../../../data/repositories/records_repository.dart';

part 'records_event.dart';
part 'records_state.dart';

class RecordsBloc extends Bloc<RecordsEvent, RecordsState> {
  final RecordsRepository _repo;
  final String petId;
  StreamSubscription<List<HealthRecord>>? _sub;

  RecordsBloc(this._repo, {required this.petId}) : super(RecordsInitial()) {
    on<RecordsLoaded>(_onLoaded);
    on<RecordsUpdated>(_onUpdated);
    on<RecordsFilterChanged>(_onFilter);
    on<RecordRemoved>(_onRemoved);
    on<RecordsErrored>((e, emit) => emit(RecordsError(e.message)));
  }

  Future<void> _onLoaded(RecordsLoaded e, Emitter<RecordsState> emit) async {
    if (state is! RecordsReady) emit(RecordsLoading());
    await _sub?.cancel();
    _sub = _repo.watchRecords(petId).listen(
      (list) async {
        final total = await _repo.getTotalSpentThisYear(petId).catchError((_) => 0.0);
        add(RecordsUpdated(list, total));
      },
      onError: (err) => _fetchOnce(emit: null),
    );
    await _fetchOnce(emit: emit);
  }

  Future<void> _fetchOnce({Emitter<RecordsState>? emit}) async {
    try {
      final list = await _repo.getRecords(petId);
      final total = await _repo.getTotalSpentThisYear(petId);
      final filter = state is RecordsReady ? (state as RecordsReady).filter : 'all';
      final ready = RecordsReady(list: list, filter: filter, totalSpentThisYear: total);
      if (emit != null) {
        emit(ready);
      } else {
        add(RecordsUpdated(list, total));
      }
    } catch (err) {
      final friendly = friendlyError(err);
      if (emit != null) {
        emit(RecordsError(friendly));
      } else {
        add(RecordsErrored(friendly));
      }
    }
  }

  void _onUpdated(RecordsUpdated e, Emitter<RecordsState> emit) {
    final filter = state is RecordsReady ? (state as RecordsReady).filter : 'all';
    emit(RecordsReady(list: e.list, filter: filter, totalSpentThisYear: e.totalSpent));
  }

  void _onFilter(RecordsFilterChanged e, Emitter<RecordsState> emit) {
    if (state is RecordsReady) {
      emit((state as RecordsReady).copyWith(filter: e.filter));
    }
  }

  Future<void> _onRemoved(RecordRemoved e, Emitter<RecordsState> emit) async {
    try {
      await _repo.deleteRecord(e.id);
      if (state is RecordsReady) {
        final s = state as RecordsReady;
        emit(s.copyWith(list: s.list.where((r) => r.id != e.id).toList()));
      }
    } catch (err) {
      emit(RecordsError(friendlyError(err)));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
