part of 'preview_bloc.dart';

abstract class PreviewEvent extends Equatable {
  const PreviewEvent();

  @override
  List<Object> get props => [];
}

class InitializeVideo extends PreviewEvent {
  final String videoPath;

  const InitializeVideo(this.videoPath);

  @override
  List<Object> get props => [videoPath];
}

class PlayVideo extends PreviewEvent {}

class PauseVideo extends PreviewEvent {}

class DisposeVideo extends PreviewEvent {}

class MakeThumbnailMove extends PreviewEvent {
  final String videoPath;

  const MakeThumbnailMove(this.videoPath);

  @override
  List<Object> get props => [videoPath];
}