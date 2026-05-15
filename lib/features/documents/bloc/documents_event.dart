part of 'documents_bloc.dart';

abstract class DocumentsEvent extends Equatable {
  const DocumentsEvent();
  @override
  List<Object?> get props => [];
}

class DocumentsLoaded extends DocumentsEvent {
  const DocumentsLoaded();
}

class DocumentsUpdated extends DocumentsEvent {
  final List<PetDocument> list;
  const DocumentsUpdated(this.list);
  @override
  List<Object?> get props => [list];
}

class DocumentsFilterChanged extends DocumentsEvent {
  final DocType? filter;
  const DocumentsFilterChanged(this.filter);
  @override
  List<Object?> get props => [filter];
}

class DocumentRemoved extends DocumentsEvent {
  final String id;
  const DocumentRemoved(this.id);
  @override
  List<Object?> get props => [id];
}

class DocumentsErrored extends DocumentsEvent {
  final String message;
  const DocumentsErrored(this.message);
  @override
  List<Object?> get props => [message];
}
