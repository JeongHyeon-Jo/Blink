abstract class SearchRepository {
  Stream<List<dynamic>> search(String query);
  Future<void> saveSearch(String query);
  Future<void> deleteSearch(String query);
}
