import 'package:blink/features/follow/data/models/follow_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FollowRepository {
  final _firestore = FirebaseFirestore.instance;

  Future<void> follow(String followerId, String followedId) async {
    try {
      final collection = _firestore.collection('follows');
      final newFollow = FollowModel(
        id: collection.doc().id,
        followerId: followerId,
        followedId: followedId,
        createdAt: DateTime.now(),
      );

      final followerRef = _firestore.collection('users').doc(followerId);
      final followedRef = _firestore.collection('users').doc(followedId);

      await _firestore.runTransaction((transaction) async {
        final followerSnapshot = await transaction.get(followerRef);
        final followedSnapshot = await transaction.get(followedRef);

        final followerData = followerSnapshot.data() as Map<String, dynamic>?;
        final followingList = List<String>.from(followerData?['following_list'] ?? []);
        if (!followingList.contains(followedId)) {
          followingList.add(followedId);
        }

        final followedData = followedSnapshot.data() as Map<String, dynamic>?;
        final followerList = List<String>.from(followedData?['follower_list'] ?? []);
        if (!followerList.contains(followerId)) {
          followerList.add(followerId);
        }

        transaction.update(followerRef, {'following_list': followingList});
        transaction.update(followedRef, {'follower_list': followerList});

        transaction.set(collection.doc(newFollow.id), newFollow.toJson());
      });
    } catch (e) {
      throw Exception('팔로우 중 오류 발생: $e');
    }
  }

  Future<void> unfollow(String followerId, String followedId) async {
    try {
      final collection = _firestore.collection('follows');

      final followerRef = _firestore.collection('users').doc(followerId);
      final followedRef = _firestore.collection('users').doc(followedId);

      await _firestore.runTransaction((transaction) async {
        final followerSnapshot = await transaction.get(followerRef);
        final followedSnapshot = await transaction.get(followedRef);

        final followerData = followerSnapshot.data() as Map<String, dynamic>?;
        final followingList = List<String>.from(followerData?['following_list'] ?? []);
        followingList.remove(followedId);

        final followedData = followedSnapshot.data() as Map<String, dynamic>?;
        final followerList = List<String>.from(followedData?['follower_list'] ?? []);
        followerList.remove(followerId);

        transaction.update(followerRef, {'following_list': followingList});
        transaction.update(followedRef, {'follower_list': followerList});

        final querySnapshot = await collection
            .where('follower_id', isEqualTo: followerId)
            .where('followed_id', isEqualTo: followedId)
            .get();

        for (var doc in querySnapshot.docs) {
          transaction.delete(doc.reference);
        }
      });
    } catch (e) {
      throw Exception('언팔로우 중 오류 발생: $e');
    }
  }

  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    final doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();

    if (!doc.exists) return false;

    final data = doc.data() as Map<String, dynamic>;
    final followingList = List<String>.from(data['following_list'] ?? []);
    return followingList.contains(targetUserId);
  }

  Future<List<FollowModel>> getFollowList(String userId, String type) async {
    try {
      final collection = _firestore.collection('follows');
      final querySnapshot = await collection
          .where(type == 'following' ? 'follower_id' : 'followed_id', isEqualTo: userId)
          .get();

      return querySnapshot.docs.map((doc) {
        return FollowModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('팔로우 목록을 가져오는 중 오류 발생: $e');
    }
  }
}
