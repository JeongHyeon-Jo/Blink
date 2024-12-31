// camera_event.dart
import 'package:equatable/equatable.dart';

abstract class CameraEvent extends Equatable {
  const CameraEvent();

  @override
  List<Object?> get props => [];
}

class InitializeCamera extends CameraEvent {}

class StartRecording extends CameraEvent {}

class StopRecording extends CameraEvent {}

class DisposeCamera extends CameraEvent {}

class PickVideoFromGallery extends CameraEvent {}