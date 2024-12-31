import 'package:blink/features/search/domain/repositories/search_repository.dart';

class DeleteSearchQuery {
  final SearchRepository repository;

  DeleteSearchQuery(this.repository);

  Future<void> call(String query) {
    return repository.deleteSearch(query);
  }
}
