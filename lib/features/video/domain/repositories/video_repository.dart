import 'package:blink/features/video/data/models/video_model.dart';

abstract class VideoRepository {
  Future<List<VideoModel>> getVideos();
  Future<void> incrementViews(String videoId);
  Future<List<VideoModel>> getVideosByUserId(String userId);
  Future<List<VideoModel>> getFollowingVideos(String userId);
  Future<List<VideoModel>> getRecommendedVideos(String? userId);
  Future<void> addToWatchList(String userId, String videoId);
}
