part of 'medications_bloc.dart';

abstract class MedicationsEvent extends Equatable {
  const MedicationsEvent();
  @override
  List<Object?> get props => [];
}

class MedicationsLoaded extends MedicationsEvent {
  const MedicationsLoaded();
}

class MedicationSaved extends MedicationsEvent {
  final Medication med;
  const MedicationSaved(this.med);
  @override
  List<Object?> get props => [med];
}

class MedicationRemoved extends MedicationsEvent {
  final String id;
  const MedicationRemoved(this.id);
  @override
  List<Object?> get props => [id];
}

class DoseGivenMarked extends MedicationsEvent {
  final String medId;
  const DoseGivenMarked(this.medId);
  @override
  List<Object?> get props => [medId];
}

class MedicationsUpdated extends MedicationsEvent {
  final List<Medication> list;
  const MedicationsUpdated(this.list);
  @override
  List<Object?> get props => [list];
}

class MedicationsErrored extends MedicationsEvent {
  final String message;
  const MedicationsErrored(this.message);
  @override
  List<Object?> get props => [message];
}
