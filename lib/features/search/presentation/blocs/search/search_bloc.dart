import 'package:blink/features/search/presentation/blocs/search/search_event.dart';
import 'package:blink/features/search/presentation/blocs/search/search_state.dart';
import 'package:bloc/bloc.dart';
import 'package:blink/features/search/domain/usecases/save_search_query.dart';
import 'package:blink/features/search/domain/usecases/delete_search_query.dart';
import 'package:blink/features/search/domain/usecases/search_query.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchQuery searchQuery;
  final SaveSearchQuery saveSearchQuery;
  final DeleteSearchQuery deleteSearchQuery;

  SearchBloc({
    required this.searchQuery,
    required this.saveSearchQuery,
    required this.deleteSearchQuery,
  }) : super(SearchInitial()) {
    on<PerformSearchEvent>((event, emit) async {
      emit(SearchLoading());
      try {
        await emit.forEach(
          searchQuery(event.query),
          onData: (data) => SearchLoaded(results: data),
          onError: (error, stackTrace) => SearchError(error.toString()),
        );
      } catch (error) {
        emit(SearchError(error.toString()));
      }
    });

    on<SaveSearchEvent>((event, emit) async {
      try {
        await saveSearchQuery(event.query);
      } catch (error) {
        emit(SearchError("Failed to save search query: ${error.toString()}"));
      }
    });

    on<DeleteSearchEvent>((event, emit) async {
      try {
        await deleteSearchQuery(event.query);
      } catch (error) {
        emit(SearchError("Failed to delete search query: ${error.toString()}"));
      }
    });
  }
}
