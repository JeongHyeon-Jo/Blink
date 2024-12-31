import 'package:shared_preferences/shared_preferences.dart';

class SearchLocalDataSource {
  static const String recentSearchesKey = "recent_searches";

  Future<List<String>> fetchRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(recentSearchesKey) ?? [];
  }

  Future<void> saveSearchQuery(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final searches = await fetchRecentSearches();

    if (!searches.contains(query)) {
      searches.insert(0, query);
      if (searches.length > 5) {
        searches.removeLast();
      }
    }
    await prefs.setStringList(recentSearchesKey, searches);
  }

  Future<void> deleteSearchQuery(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final searches = await fetchRecentSearches();
    searches.remove(query);
    await prefs.setStringList(recentSearchesKey, searches);
  }
}
