part of 'documents_bloc.dart';

abstract class DocumentsState extends Equatable {
  const DocumentsState();
  @override
  List<Object?> get props => [];
}

class DocumentsInitial extends DocumentsState {}
class DocumentsLoading extends DocumentsState {}

class DocumentsReady extends DocumentsState {
  final List<PetDocument> list;
  final DocType? filter;
  const DocumentsReady({required this.list, this.filter});

  List<PetDocument> get filtered =>
      filter == null ? list : list.where((d) => d.type == filter).toList();

  DocumentsReady copyWith({
    List<PetDocument>? list,
    DocType? filter,
    bool clearFilter = false,
  }) =>
      DocumentsReady(
        list: list ?? this.list,
        filter: clearFilter ? null : (filter ?? this.filter),
      );

  @override
  List<Object?> get props => [list, filter];
}

class DocumentsError extends DocumentsState {
  final String message;
  const DocumentsError(this.message);
  @override
  List<Object?> get props => [message];
}
