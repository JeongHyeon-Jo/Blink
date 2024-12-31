import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/comment_model.dart';
import 'package:blink/core/utils/blink_sharedpreference.dart';

class CommentRepository {
  final _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final _sharedPreference = BlinkSharedPreference();

  Future<List<CommentModel>> getComments(String videoId) async {
    try {
      final querySnapshot = await _firestore
          .collection('comments')
          .where('video_id', isEqualTo: videoId)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CommentModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting comments: $e');
      return [];
    }
  }

  Future<void> addComment(
      String videoId, String writerId, String content) async {
    try {
      final userDoc = await _firestore.collection('users').doc(writerId).get();
      final writerNickname = userDoc.data()?['nickname'] ?? writerId;
      final writerProfileUrl = userDoc.data()?['profile_image_url'];

      final commentModel = CommentModel(
        id: _uuid.v4(),
        writerId: writerId,
        writerNickname: writerNickname,
        videoId: videoId,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        writerProfileUrl: writerProfileUrl,
      );

      await _firestore
          .collection('comments')
          .doc(commentModel.id)
          .set(commentModel.toJson());

      await _firestore.collection('videos').doc(videoId).update({
        'comment_list': FieldValue.arrayUnion([commentModel.id])
      });
    } catch (e) {
      print('Error adding comment: $e');
      throw Exception('댓글 추가 중 오류가 발생했습니다');
    }
  }

  Future<void> deleteComment(String videoId, String commentId) async {
    try {
      await _firestore.collection('comments').doc(commentId).delete();
      await _firestore.collection('videos').doc(videoId).update({
        'comment_list': FieldValue.arrayRemove([commentId])
      });
    } catch (e) {
      print('Error deleting comment: $e');
      throw Exception('댓글 삭제 중 오류가 발생했습니다');
    }
  }

  Future<int> getCommentCount(String videoId) async {
    try {
      final videoDoc = await _firestore.collection('videos').doc(videoId).get();
      final commentList =
          List<String>.from(videoDoc.data()?['comment_list'] ?? []);
      return commentList.length;
    } catch (e) {
      print('Error getting comment count: $e');
      return 0;
    }
  }

  Future<void> updateComment(String commentId, String content) async {
    try {
      await _firestore.collection('comments').doc(commentId).update({
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating comment: $e');
      throw Exception('댓글 수정 중 오류가 발생했습니다');
    }
  }
}
