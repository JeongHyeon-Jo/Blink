import 'package:blink/features/search/domain/repositories/search_repository.dart';

class SearchQuery {
  final SearchRepository repository;

  SearchQuery(this.repository);

  Stream<List<dynamic>> call(String query) {
    return repository.search(query);
  }
}
