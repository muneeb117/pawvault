part of 'records_bloc.dart';

abstract class RecordsEvent extends Equatable {
  const RecordsEvent();
  @override
  List<Object?> get props => [];
}

class RecordsLoaded extends RecordsEvent {
  const RecordsLoaded();
}

class RecordsFilterChanged extends RecordsEvent {
  final String filter; // all | vet | vaccine | medication | procedure | other
  const RecordsFilterChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}

class RecordRemoved extends RecordsEvent {
  final String id;
  const RecordRemoved(this.id);
  @override
  List<Object?> get props => [id];
}

class RecordsUpdated extends RecordsEvent {
  final List<HealthRecord> list;
  final double totalSpent;
  const RecordsUpdated(this.list, this.totalSpent);
  @override
  List<Object?> get props => [list, totalSpent];
}

class RecordsErrored extends RecordsEvent {
  final String message;
  const RecordsErrored(this.message);
  @override
  List<Object?> get props => [message];
}
