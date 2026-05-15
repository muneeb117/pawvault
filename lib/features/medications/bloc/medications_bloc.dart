import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/models/medication_model.dart';
import '../../../data/repositories/medication_repository.dart';

part 'medications_event.dart';
part 'medications_state.dart';

class MedicationsBloc extends Bloc<MedicationsEvent, MedicationsState> {
  final MedicationRepository _repo;
  final String petId;
  StreamSubscription<List<Medication>>? _sub;

  MedicationsBloc(this._repo, {required this.petId}) : super(MedicationsInitial()) {
    on<MedicationsLoaded>(_onLoaded);
    on<MedicationsUpdated>(_onUpdated);
    on<MedicationSaved>(_onSaved);
    on<MedicationRemoved>(_onRemoved);
    on<DoseGivenMarked>(_onDoseGiven);
    on<MedicationsErrored>((e, emit) => emit(MedicationsError(e.message)));
  }

  Future<void> _onLoaded(MedicationsLoaded e, Emitter<MedicationsState> emit) async {
    if (state is! MedicationsReady) emit(MedicationsLoading());
    await _sub?.cancel();
    _sub = _repo.watchMedications(petId).listen(
      (list) => add(MedicationsUpdated(list)),
      onError: (err) => _fetchOnce(emit: null),
    );
    await _fetchOnce(emit: emit);
  }

  Future<void> _fetchOnce({Emitter<MedicationsState>? emit}) async {
    try {
      final list = await _repo.getMedications(petId);
      final ready = MedicationsReady(list: list);
      if (emit != null) {
        emit(ready);
      } else {
        add(MedicationsUpdated(list));
      }
    } catch (err) {
      final friendly = friendlyError(err);
      if (emit != null) {
        emit(MedicationsError(friendly));
      } else {
        add(MedicationsErrored(friendly));
      }
    }
  }

  void _onUpdated(MedicationsUpdated e, Emitter<MedicationsState> emit) {
    emit(MedicationsReady(list: e.list));
  }

  Future<void> _onSaved(MedicationSaved e, Emitter<MedicationsState> emit) async {
    try {
      final existing = state is MedicationsReady
          ? (state as MedicationsReady).list.any((m) => m.id == e.med.id)
          : false;
      if (existing) {
        await _repo.updateMedication(e.med);
      } else {
        await _repo.addMedication(e.med);
      }
      await _fetchOnce(emit: emit);
    } catch (err) {
      emit(MedicationsError(friendlyError(err)));
    }
  }

  Future<void> _onRemoved(MedicationRemoved e, Emitter<MedicationsState> emit) async {
    try {
      final ms = state is MedicationsReady ? (state as MedicationsReady).list : <Medication>[];
      final m = ms.firstWhere((x) => x.id == e.id, orElse: () => throw 'Not found');
      final inactive = Medication(
        id: m.id, petId: m.petId, name: m.name, category: m.category,
        frequency: m.frequency, dosage: m.dosage, remainingCount: m.remainingCount,
        nextDoseAt: m.nextDoseAt, isActive: false,
        startDate: m.startDate, endDate: DateTime.now(),
        createdAt: m.createdAt,
      );
      await _repo.updateMedication(inactive);
      emit(MedicationsReady(list: ms.where((x) => x.id != e.id).toList()));
    } catch (err) {
      emit(MedicationsError(friendlyError(err)));
    }
  }

  Future<void> _onDoseGiven(DoseGivenMarked e, Emitter<MedicationsState> emit) async {
    try {
      await _repo.markDoseGiven(e.medId);
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
