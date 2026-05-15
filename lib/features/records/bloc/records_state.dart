part of 'records_bloc.dart';

abstract class RecordsState extends Equatable {
  const RecordsState();
  @override
  List<Object?> get props => [];
}

class RecordsInitial extends RecordsState {}
class RecordsLoading extends RecordsState {}

class RecordsReady extends RecordsState {
  final List<HealthRecord> list;
  final String filter;
  final double totalSpentThisYear;

  const RecordsReady({required this.list, required this.filter, required this.totalSpentThisYear});

  List<HealthRecord> get filtered {
    if (filter == 'all') return list;
    try {
      final t = RecordType.values.byName(filter);
      return list.where((r) => r.type == t).toList();
    } catch (_) {
      return list;
    }
  }

  /// Groups records by month label e.g. "MAY 2026"
  Map<String, List<HealthRecord>> get groupedByMonth {
    final out = <String, List<HealthRecord>>{};
    for (final r in filtered) {
      final key = '${_monthName(r.date.month)} ${r.date.year}';
      out.putIfAbsent(key, () => []).add(r);
    }
    return out;
  }

  static String _monthName(int m) =>
      const ['JANUARY','FEBRUARY','MARCH','APRIL','MAY','JUNE','JULY','AUGUST',
              'SEPTEMBER','OCTOBER','NOVEMBER','DECEMBER'][m - 1];

  RecordsReady copyWith({
    List<HealthRecord>? list, String? filter, double? totalSpentThisYear,
  }) => RecordsReady(
        list: list ?? this.list,
        filter: filter ?? this.filter,
        totalSpentThisYear: totalSpentThisYear ?? this.totalSpentThisYear,
      );

  @override
  List<Object?> get props => [list, filter, totalSpentThisYear];
}

class RecordsError extends RecordsState {
  final String message;
  const RecordsError(this.message);
  @override
  List<Object?> get props => [message];
}
