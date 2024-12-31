import 'package:blink/features/search/domain/repositories/search_repository.dart';

class SaveSearchQuery {
  final SearchRepository repository;

  SaveSearchQuery(this.repository);

  Future<void> call(String query) {
    return repository.saveSearch(query);
  }
}
