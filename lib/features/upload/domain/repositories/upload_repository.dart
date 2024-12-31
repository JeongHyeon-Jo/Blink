import 'dart:io';

import 'package:blink/core/utils/blink_sharedpreference.dart';
import 'package:blink/core/utils/result.dart';
import 'package:blink/features/video/data/models/video_model.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UploadRepository {
  final FirebaseStorage _fireStorage = FirebaseStorage.instance;

  Future<Result> uploadVideo(String videoPath, String thumbnailPath, String title, String description, String category, List<String> hashTags) async {
    final userId = await BlinkSharedPreference().getCurrentUserId();

    try {
      // 사용자 정보 가져오기
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final userNickName = userDoc.data()?['nickname'] ?? '';

      // 공통으로 사용할 타임스탬프와 폴더명
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final folderName = 'videos/$timestamp';

      // 비디오 업로드
      final videoFileName = 'video.mp4';
      final videoRef = _fireStorage.ref().child('$folderName/$videoFileName');
      final videoUploadTask = await videoRef.putFile(File(videoPath));
      final videoUrl = await videoUploadTask.ref.getDownloadURL();

      // 썸네일 업로드
      final thumbnailFileName = 'thumbnail.jpg';
      final thumbnailRef = _fireStorage.ref().child('$folderName/$thumbnailFileName');
      final thumbnailUploadTask = await thumbnailRef.putFile(File(thumbnailPath));
      final thumbnailUrl = await thumbnailUploadTask.ref.getDownloadURL();

      final uploadVideoRef = FirebaseFirestore.instance.collection('videos').doc();

      final videoModel = VideoModel(
          id: uploadVideoRef.id,
          uploaderId: userId,
          userNickName: userNickName,
          userName: userNickName,
          title: title,
          description: description,
          videoUrl: videoUrl,
          thumbnailUrl: thumbnailUrl,
          hashTagList: hashTags,
          views: 0,
          categoryId: category,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now());

      // Firestore에 정보 저장
      await uploadVideoRef.set(videoModel.toJson());
      await updateHashtagsInFirebase(hashTags);

      return Result.success("업로드 성공");
    } catch (e) {
      return Result.failure("업로드 실패 error : $e");
    }
  }

  Future<void> updateHashtagsInFirebase(List<String> hashtags) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (String tag in hashtags) {
        // '#' 제거
        String query = tag.startsWith('#') ? tag.substring(1) : tag;

        // 해당 query로 문서 찾기
        final querySnapshot = await firestore
            .collection('hashtags')
            .where('query', isEqualTo: query)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // 이미 존재하는 경우 count 증가
          final docRef = querySnapshot.docs.first.reference;
          batch.update(docRef, {
            'count': FieldValue.increment(1)
          });
        } else {
          // 새로운 해시태그인 경우 문서 생성
          final newDocRef = firestore.collection('hashtags').doc();
          batch.set(newDocRef, {
            'query': query,
            'count': 1
          });
        }
      }

      // 일괄 처리 실행
      await batch.commit();
      print('해시태그 업데이트 완료');

    } catch (e) {
      print('해시태그 업데이트 중 오류 발생: $e');
      throw e;
    }
  }
}
