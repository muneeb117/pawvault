part of 'vaccines_bloc.dart';

abstract class VaccinesEvent extends Equatable {
  const VaccinesEvent();
  @override
  List<Object?> get props => [];
}

class VaccinesLoaded extends VaccinesEvent {
  const VaccinesLoaded();
}

class VaccineSaved extends VaccinesEvent {
  final Vaccine vaccine;
  const VaccineSaved(this.vaccine);
  @override
  List<Object?> get props => [vaccine];
}

class VaccineRemoved extends VaccinesEvent {
  final String id;
  const VaccineRemoved(this.id);
  @override
  List<Object?> get props => [id];
}

class VaccinesFilterChanged extends VaccinesEvent {
  final String filter; // all | upcoming | overdue | upToDate
  const VaccinesFilterChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}

class VaccinesUpdated extends VaccinesEvent {
  final List<Vaccine> list;
  const VaccinesUpdated(this.list);
  @override
  List<Object?> get props => [list];
}

class VaccinesErrored extends VaccinesEvent {
  final String message;
  const VaccinesErrored(this.message);
  @override
  List<Object?> get props => [message];
}
