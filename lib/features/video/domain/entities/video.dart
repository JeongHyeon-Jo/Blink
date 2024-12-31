class Video {
  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final String musicName;
  final String userName;
  final String userNickName;
  final String uploaderId;
  final int likes;
  final int comments;
  final int shares;
  final double score;

  Video({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.caption,
    required this.musicName,
    required this.userName,
    required this.userNickName,
    required this.uploaderId,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.score,
  });
}
