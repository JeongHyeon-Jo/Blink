import 'package:blink/features/video/domain/entities/video.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  // 비디오 아이디
  final String id;

  // 비디오 올린 유저 아이디 (필수)
  final String uploaderId;

  // 유저 닉네임 (필수)
  final String userNickName;

  // 비디오 제목 (필수)
  final String title;

  // 비디오 설명 (필수)
  final String description;

  // 비디오 영상 링크 (필수)
  final String videoUrl;

  // 썸네일 사진 링크 (필수)
  final String thumbnailUrl;

  // 조회수
  final int views;

  // 점수 (추천 기준)
  final double score;

  // 카테고리 아이디
  final String categoryId;

  // 댓글 리스트 (댓글 ID 목록)
  final List<String> commentList;

  // 좋아요 리스트 (좋아요 ID 목록)
  final List<String> likeList;

  // 해시태그 리스트
  final List<String> hashTagList;

  // 생성일
  final DateTime? createdAt;

  // 수정일
  final DateTime? updatedAt;

  // 유저네임 (@username)
  final String userName;

  VideoModel({
    this.id = '',
    required this.uploaderId,
    required this.userNickName,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    this.views = 0,
    this.score = 0,
    this.categoryId = '',
    this.commentList = const [],
    this.likeList = const [],
    this.hashTagList = const [],
    required this.createdAt,
    required this.updatedAt,
    required this.userName,
  });

  // JSON -> VideoModel
  factory VideoModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value);
      }
      return null; // 유효하지 않은 경우 null 반환
    }

    return VideoModel(
      id: json['id'] ?? '',
      uploaderId: json['uploader_id'] ?? '',
      userNickName: json['user_nickname'] ?? json['nickname'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      videoUrl: json['video_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      views: json['views'] ?? 0,
      score: json['score'] ?? 0,
      categoryId: json['category_id'] ?? '',
      commentList: (json['comment_list'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      likeList: (json['like_list'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      hashTagList: (json['hash_tag_list'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: parseDateTime(json['created_at']),
      updatedAt: parseDateTime(json['updated_at']),
      userName: json['user_name'] ?? '',
    );
  }

  // VideoModel -> JSON
  Map<String, dynamic> toJson() {
    Timestamp? toTimestamp(DateTime? dateTime) {
      return dateTime != null ? Timestamp.fromDate(dateTime) : null;
    }

    return {
      'id': id.isNotEmpty ? id : null,
      'uploader_id': uploaderId,
      'user_nickname': userNickName,
      'title': title,
      'description': description,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'views': views,
      'score': score,
      'category_id': categoryId,
      'comment_list': commentList,
      'like_list': likeList,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'user_name': userName,
      'hash_tag_list': hashTagList,
    };
  }

  // VideoModel 클래스 내부에 추가
  Video toEntity() {
    return Video(
      id: id,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      caption: description,
      musicName: title,
      userName: userName,
      userNickName: userNickName,
      uploaderId: uploaderId,
      likes: likeList.length,
      comments: commentList.length,
      shares: views,
      score: score,
    );
  }

  VideoModel copyWith({
    String? id,
    String? uploaderId,
    String? userNickName,
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnailUrl,
    int? views,
    double? score,
    String? categoryId,
    List<String>? commentList,
    List<String>? likeList,
    List<String>? hashTagList,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
  }) {
    return VideoModel(
      id: id ?? this.id,
      uploaderId: uploaderId ?? this.uploaderId,
      userNickName: userNickName ?? this.userNickName,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      views: views ?? this.views,
      score: score ?? this.score,
      categoryId: categoryId ?? this.categoryId,
      commentList: commentList ?? this.commentList,
      likeList: likeList ?? this.likeList,
      hashTagList: hashTagList ?? this.hashTagList,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
    );
  }
}
