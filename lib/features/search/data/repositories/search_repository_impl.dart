import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blink/features/search/domain/repositories/search_repository.dart';
import 'package:blink/features/search/data/datasources/remote/search_remote_datasource.dart';
import 'package:rxdart/rxdart.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;

  SearchRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<dynamic>> search(String query) {
    return Rx.combineLatest3(
      remoteDataSource.fetchUsers(),
      remoteDataSource.fetchVideos(),
      remoteDataSource.fetchHashtags(),
      (QuerySnapshot userSnapshot, QuerySnapshot videoSnapshot, QuerySnapshot hashtagSnapshot) {
        // 사용자 검색
        final users = userSnapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['name'].toString().contains(query) ||
              data['nickname'].toString().contains(query) ||
              data['email'].toString().contains(query);
        }).map((doc) => {'type': 'user', 'data': doc.data()}).toList();

        // 동영상 검색
        final videos = videoSnapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final uploaderId = data['uploader_id'] ?? '';
          final uploader = userSnapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>?>().firstWhere(
            (userDoc) => userDoc?.id == uploaderId,
            orElse: () => null,
          );

          if (uploader != null) {
            final uploaderData = uploader.data() as Map<String, dynamic>;
            return uploaderData['name'].toString().contains(query) ||
                uploaderData['nickname'].toString().contains(query) ||
                data['title'].toString().contains(query) ||
                data['description'].toString().contains(query);
          }

          return data['title'].toString().contains(query) || 
                data['description'].toString().contains(query);
        }).map((doc) => {'type': 'video', 'data': doc.data()}).toList();

        // 해시태그 검색
        final hashtags = hashtagSnapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['tag'].toString().contains(query);
        }).map((doc) => {'type': 'hashtag', 'data': doc.data()}).toList();

        return [...users, ...videos, ...hashtags];
      },
    );
  }

  @override
  Future<void> saveSearch(String query) {
    return remoteDataSource.saveSearchQuery(query);
  }

  @override
  Future<void> deleteSearch(String query) {
    return remoteDataSource.deleteSearchQuery(query);
  }
}
