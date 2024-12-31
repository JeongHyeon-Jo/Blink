part of 'preview_bloc.dart';

abstract class PreviewState extends Equatable {
  const PreviewState();

  @override
  List<Object?> get props => [];
}

class VideoPlayerInitial extends PreviewState {}

class VideoPlayerLoading extends PreviewState {}

class VideoPlayerReady extends PreviewState {
  final VideoPlayerController controller;
  final bool isPlaying;
  final Duration position;
  final Duration duration;

  const VideoPlayerReady({
    required this.controller,
    required this.isPlaying,
    required this.position,
    required this.duration,
  });

  VideoPlayerReady copyWith({
    VideoPlayerController? controller,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
  }) {
    return VideoPlayerReady(
      controller: controller ?? this.controller,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }

  @override
  List<Object?> get props => [controller, isPlaying, position, duration];
}

class VideoPlayerError extends PreviewState {
  final String message;

  const VideoPlayerError(this.message);

  @override
  List<Object> get props => [message];
}

// 썸네일 관련 상태 추가
class ThumbnailGenerating extends PreviewState {}

class ThumbnailGenerated extends PreviewState {
  final String thumbnailPath;

  const ThumbnailGenerated(this.thumbnailPath);

  @override
  List<Object> get props => [thumbnailPath];
}

class ThumbnailGenerateError extends PreviewState {
  final String error;

  const ThumbnailGenerateError(this.error);

  @override
  List<Object> get props => [error];
}