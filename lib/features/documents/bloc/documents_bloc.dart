import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/utils/error_messages.dart';
import '../../../data/models/document_model.dart';
import '../../../data/repositories/documents_repository.dart';

part 'documents_event.dart';
part 'documents_state.dart';

class DocumentsBloc extends Bloc<DocumentsEvent, DocumentsState> {
  final DocumentsRepository _repo;
  final String petId;
  StreamSubscription<List<PetDocument>>? _sub;

  DocumentsBloc(this._repo, {required this.petId}) : super(DocumentsInitial()) {
    on<DocumentsLoaded>(_onLoaded);
    on<DocumentsUpdated>((e, emit) {
      final filter = state is DocumentsReady ? (state as DocumentsReady).filter : null;
      emit(DocumentsReady(list: e.list, filter: filter));
    });
    on<DocumentsFilterChanged>((e, emit) {
      if (state is DocumentsReady) {
        emit((state as DocumentsReady).copyWith(filter: e.filter, clearFilter: e.filter == null));
      }
    });
    on<DocumentRemoved>(_onRemoved);
    on<DocumentsErrored>((e, emit) => emit(DocumentsError(e.message)));
  }

  Future<void> _onLoaded(DocumentsLoaded e, Emitter<DocumentsState> emit) async {
    if (state is! DocumentsReady) emit(DocumentsLoading());
    await _sub?.cancel();
    _sub = _repo.watchDocuments(petId).listen(
      (list) => add(DocumentsUpdated(list)),
      onError: (_) => _fetchOnce(emit: null),
    );
    await _fetchOnce(emit: emit);
  }

  Future<void> _fetchOnce({Emitter<DocumentsState>? emit}) async {
    try {
      final list = await _repo.getDocuments(petId);
      if (emit != null) {
        emit(DocumentsReady(list: list));
      } else {
        add(DocumentsUpdated(list));
      }
    } catch (err) {
      final friendly = friendlyError(err);
      if (emit != null) {
        emit(DocumentsError(friendly));
      } else {
        add(DocumentsErrored(friendly));
      }
    }
  }

  Future<void> _onRemoved(DocumentRemoved e, Emitter<DocumentsState> emit) async {
    try {
      await _repo.deleteDocument(e.id);
      if (state is DocumentsReady) {
        final s = state as DocumentsReady;
        emit(s.copyWith(list: s.list.where((d) => d.id != e.id).toList()));
      }
    } catch (err) {
      emit(DocumentsError(friendlyError(err)));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
