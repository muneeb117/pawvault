import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/models/vaccine_model.dart';
import '../../../data/repositories/vaccine_repository.dart';

part 'vaccines_event.dart';
part 'vaccines_state.dart';

class VaccinesBloc extends Bloc<VaccinesEvent, VaccinesState> {
  final VaccineRepository _repo;
  final String petId;
  StreamSubscription<List<Vaccine>>? _sub;

  VaccinesBloc(this._repo, {required this.petId}) : super(VaccinesInitial()) {
    on<VaccinesLoaded>(_onLoaded);
    on<VaccinesUpdated>(_onUpdated);
    on<VaccineSaved>(_onSaved);
    on<VaccineRemoved>(_onRemoved);
    on<VaccinesFilterChanged>(_onFilter);
    on<VaccinesErrored>((e, emit) => emit(VaccinesError(e.message)));
  }

  Future<void> _onLoaded(VaccinesLoaded e, Emitter<VaccinesState> emit) async {
    if (state is! VaccinesReady) emit(VaccinesLoading());
    await _sub?.cancel();
    _sub = _repo.watchVaccines(petId).listen(
      (list) => add(VaccinesUpdated(list)),
      onError: (err) {
        // Fall back to one-shot fetch if realtime fails (e.g. publication off)
        _fetchOnce(emit: null);
      },
    );
    // Initial fetch for snappy first render — stream will update if realtime arrives.
    await _fetchOnce(emit: emit);
  }

  Future<void> _fetchOnce({Emitter<VaccinesState>? emit}) async {
    try {
      final list = await _repo.getVaccines(petId);
      final filter = state is VaccinesReady ? (state as VaccinesReady).filter : 'all';
      final ready = VaccinesReady(list: list, filter: filter);
      if (emit != null) {
        emit(ready);
      } else {
        add(VaccinesUpdated(list));
      }
    } catch (err) {
      final friendly = friendlyError(err);
      if (emit != null) {
        emit(VaccinesError(friendly));
      } else {
        add(VaccinesErrored(friendly));
      }
    }
  }

  void _onUpdated(VaccinesUpdated e, Emitter<VaccinesState> emit) {
    final filter = state is VaccinesReady ? (state as VaccinesReady).filter : 'all';
    emit(VaccinesReady(list: e.list, filter: filter));
  }

  Future<void> _onSaved(VaccineSaved e, Emitter<VaccinesState> emit) async {
    try {
      final existing = state is VaccinesReady
          ? (state as VaccinesReady).list.any((v) => v.id == e.vaccine.id)
          : false;
      if (existing) {
        await _repo.updateVaccine(e.vaccine);
      } else {
        await _repo.addVaccine(e.vaccine);
      }
      // Stream will deliver the update. Also fetch in case realtime is off.
      await _fetchOnce(emit: emit);
    } catch (err) {
      emit(VaccinesError(friendlyError(err)));
    }
  }

  Future<void> _onRemoved(VaccineRemoved e, Emitter<VaccinesState> emit) async {
    try {
      await _repo.deleteVaccine(e.id);
      if (state is VaccinesReady) {
        final s = state as VaccinesReady;
        emit(s.copyWith(list: s.list.where((v) => v.id != e.id).toList()));
      }
    } catch (err) {
      emit(VaccinesError(friendlyError(err)));
    }
  }

  void _onFilter(VaccinesFilterChanged e, Emitter<VaccinesState> emit) {
    if (state is VaccinesReady) {
      emit((state as VaccinesReady).copyWith(filter: e.filter));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
