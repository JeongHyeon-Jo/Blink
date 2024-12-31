import 'package:blink/features/video/data/models/video_model.dart';
import 'package:blink/features/video/domain/repositories/video_repository.dart';

class GetUserVideos {
  final VideoRepository repository;

  GetUserVideos(this.repository);

  Future<List<VideoModel>> call(String userId) async {
    return await repository.getVideosByUserId(userId);
  }
}
