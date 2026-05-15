part of 'medications_bloc.dart';

abstract class MedicationsState extends Equatable {
  const MedicationsState();
  @override
  List<Object?> get props => [];
}

class MedicationsInitial extends MedicationsState {}
class MedicationsLoading extends MedicationsState {}

class MedicationsReady extends MedicationsState {
  final List<Medication> list;
  const MedicationsReady({required this.list});

  int get lowRefillCount => list.where((m) => m.isLowRefill).length;

  @override
  List<Object?> get props => [list];
}

class MedicationsError extends MedicationsState {
  final String message;
  const MedicationsError(this.message);
  @override
  List<Object?> get props => [message];
}
