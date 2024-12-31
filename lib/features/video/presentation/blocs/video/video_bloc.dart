import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/video.dart';
import '../../../domain/repositories/video_repository.dart';
import 'package:blink/core/utils/blink_sharedpreference.dart';

part 'video_event.dart';
part 'video_state.dart';

class VideoBloc extends Bloc<VideoEvent, VideoState> {
  final VideoRepository _videoRepository;
  final _sharedPreference = BlinkSharedPreference();

  VideoBloc({required VideoRepository videoRepository})
      : _videoRepository = videoRepository,
        super(VideoInitial()) {
    on<LoadVideos>(_onLoadVideos);
    on<LoadFollowingVideos>(_onLoadFollowingVideos);
    on<LoadRecommendedVideos>(_onLoadRecommendedVideos);
    on<ChangeVideo>(_onChangeVideo);
  }

  Future<void> _onLoadVideos(LoadVideos event, Emitter<VideoState> emit) async {
    emit(VideoLoading());
    try {
      final videos = await _videoRepository.getVideos();
      print('Loaded ${videos.length} videos');
      if (videos.isEmpty) {
        emit(VideoError(message: '비디오가 없습니다.'));
      } else {
        emit(VideoLoaded(
          videos: videos.map((model) => model.toEntity()).toList(),
          currentIndex: 0,
        ));
      }
    } catch (e, stackTrace) {
      print('Error in VideoBloc: $e');
      print('StackTrace: $stackTrace');
      emit(VideoError(message: e.toString()));
    }
  }

  Future<void> _onLoadFollowingVideos(
      LoadFollowingVideos event, Emitter<VideoState> emit) async {
    emit(VideoLoading());
    try {
      final currentUserId = await _sharedPreference.getCurrentUserId();
      if (currentUserId.isEmpty) {
        emit(VideoError(message: '로그인이 필요합니다.'));
        return;
      }

      final videos = await _videoRepository.getFollowingVideos(currentUserId);
      print('Loaded ${videos.length} following videos');
      if (videos.isEmpty) {
        emit(VideoError(message: '팔로잉한 유저의 비디오가 없습니다.'));
      } else {
        emit(VideoLoaded(
          videos: videos.map((model) => model.toEntity()).toList(),
          currentIndex: 0,
        ));
      }
    } catch (e, stackTrace) {
      print('Error in VideoBloc: $e');
      print('StackTrace: $stackTrace');
      if (e.toString().contains('permission-denied')) {
        emit(VideoError(message: '권한이 없습니다. 다시 로그인해주세요.'));
      } else {
        emit(VideoError(message: '팔로잉한 유저의 비디오를 불러오는데 실패했습니다.'));
      }
    }
  }

  Future<void> _onLoadRecommendedVideos(LoadRecommendedVideos event, Emitter<VideoState> emit) async {
    emit(VideoLoading());
    try {
      final currentUserId = await _sharedPreference.getCurrentUserId();

      // 로그인 여부와 상관없이 추천 비디오 로드
      final videos = await _videoRepository.getRecommendedVideos(
        currentUserId.isEmpty ? null : currentUserId,
      );

      if (videos.isEmpty) {
        emit(VideoError(message: '추천할 비디오가 없습니다.'));
      } else {
        emit(VideoLoaded(
          videos: videos.map((model) => model.toEntity()).toList(),
          currentIndex: 0,
        ));
      }
    } catch (e) {
      emit(VideoError(message: '추천 비디오를 불러오는데 실패했습니다.'));
    }
  }

  void _onChangeVideo(ChangeVideo event, Emitter<VideoState> emit) async {
    if (state is VideoLoaded) {
      final currentState = state as VideoLoaded;
      final currentUserId = await _sharedPreference.getCurrentUserId();

      if (currentUserId.isNotEmpty) {
        // 시청 목록에 추가 및 조회수 증가
        await _videoRepository.addToWatchList(
            currentUserId, currentState.videos[event.index].id);
      }

      emit(currentState.copyWith(currentIndex: event.index));
    }
  }
}
