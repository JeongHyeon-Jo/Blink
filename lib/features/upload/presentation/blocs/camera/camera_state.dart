import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';

abstract class CameraState extends Equatable {
  const CameraState();

  @override
  List<Object?> get props => [];
}

class CameraInitial extends CameraState {}

class CameraInitialized extends CameraState {
  final CameraController controller;

  const CameraInitialized(this.controller);

  @override
  List<Object?> get props => [controller];
}

class CameraRecording extends CameraState {
  final CameraController controller;

  const CameraRecording(this.controller);

  @override
  List<Object?> get props => [controller];
}

class CameraError extends CameraState {
  final String message;

  const CameraError(this.message);

  @override
  List<Object?> get props => [message];
}

class VideoSelected extends CameraState {
  final XFile video;

  VideoSelected(this.video);
}