enum LikeStatus { like, dislike }

class LikeModel {
  // 좋아요 아이디
  final String id;

  // 좋아요 누른 유저 아이디
  final String userId;

  // 좋아요 눌린 비디오 아이디
  final String? videoId;

  // 좋아요 타임 // like, dislike 둘 중 하나
  final LikeStatus? type;

  // 추가한 날짜 // 좋아요 추가한 순서로 정렬될 때 사용될듯
  final DateTime createdAt;

  LikeModel({
    required this.id,
    required this.userId,
    this.videoId,
    this.type,
    required this.createdAt,
  });

  // JSON -> LikeModel
  factory LikeModel.fromJson(Map<String, dynamic> json) {
    return LikeModel(
      id: json['id'],
      userId: json['user_id'],
      videoId: json['video_id'],
      type: _stringToLikeStatus(json['type']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // LikeModel -> JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'video_id': videoId,
      'type': type?.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // String To LikeStatus 문자열 enum으로 변환
  static LikeStatus? _stringToLikeStatus(String? status) {
    if (status == null) return null;
    return LikeStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => throw ArgumentError('유효하지않은 LikeStatus: $status'),
    );
  }
}
