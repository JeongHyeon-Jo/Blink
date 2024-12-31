import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SearchRemoteDataSource {
  final FirebaseFirestore firestore;

  SearchRemoteDataSource({required this.firestore});

  Stream<QuerySnapshot> fetchUsers() {
    return firestore.collection('users').snapshots();
  }

  Stream<QuerySnapshot> fetchVideos() {
    return firestore.collection('videos').snapshots();
  }

  Stream<QuerySnapshot> fetchHashtags() {
    return firestore.collection('hashtags').snapshots();
  }

  Future<void> saveSearchQuery(String query) async {
    try {
      final collectionRef = firestore.collection('searches');

      final snapshot = await collectionRef.limit(1).get();
      if (snapshot.docs.isEmpty) {
        await collectionRef.add({
          'query': 'default_query',
          'timestamp': FieldValue.serverTimestamp(),
        });
        debugPrint('searches 컬렉션이 생성되었습니다.');
      }

      await collectionRef.add({
        'query': query,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('검색어 저장 중 오류 발생: $e');
    }
  }

  Future<void> deleteSearchQuery(String query) async {
    final snapshots = await firestore
        .collection('searches')
        .where('query', isEqualTo: query)
        .get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }
}
