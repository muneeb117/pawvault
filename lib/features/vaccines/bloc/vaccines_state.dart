part of 'vaccines_bloc.dart';

abstract class VaccinesState extends Equatable {
  const VaccinesState();
  @override
  List<Object?> get props => [];
}

class VaccinesInitial extends VaccinesState {}
class VaccinesLoading extends VaccinesState {}

class VaccinesReady extends VaccinesState {
  final List<Vaccine> list;
  final String filter;
  const VaccinesReady({required this.list, required this.filter});

  List<Vaccine> get filtered {
    switch (filter) {
      case 'upcoming':  return list.where((v) => v.status == VaccineStatus.dueSoon).toList();
      case 'upToDate':  return list.where((v) => v.status == VaccineStatus.upToDate).toList();
      case 'overdue':   return list.where((v) => v.status == VaccineStatus.overdue).toList();
      default:          return list;
    }
  }

  int get upCount   => list.where((v) => v.status == VaccineStatus.upToDate).length;
  int get dueCount  => list.where((v) => v.status == VaccineStatus.dueSoon).length;
  int get overCount => list.where((v) => v.status == VaccineStatus.overdue).length;

  Vaccine? get nextDue {
    final upcoming = list.where((v) => v.status != VaccineStatus.overdue).toList()
      ..sort((a, b) => a.nextDue.compareTo(b.nextDue));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  VaccinesReady copyWith({List<Vaccine>? list, String? filter}) => VaccinesReady(
        list: list ?? this.list,
        filter: filter ?? this.filter,
      );

  @override
  List<Object?> get props => [list, filter];
}

class VaccinesError extends VaccinesState {
  final String message;
  const VaccinesError(this.message);
  @override
  List<Object?> get props => [message];
}
