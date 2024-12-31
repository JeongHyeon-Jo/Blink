part of 'video_bloc.dart';

abstract class VideoState extends Equatable {
  @override
  List<Object?> get props => [];
}

class VideoInitial extends VideoState {}

class VideoLoading extends VideoState {}

class VideoLoaded extends VideoState {
  final List<Video> videos;
  final int currentIndex;

  VideoLoaded({
    required this.videos,
    required this.currentIndex,
  });

  VideoLoaded copyWith({
    List<Video>? videos,
    int? currentIndex,
  }) {
    return VideoLoaded(
      videos: videos ?? this.videos,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  @override
  List<Object?> get props => [videos, currentIndex];
}

class VideoError extends VideoState {
  final String message;

  VideoError({required this.message});

  @override
  List<Object?> get props => [message];
}
