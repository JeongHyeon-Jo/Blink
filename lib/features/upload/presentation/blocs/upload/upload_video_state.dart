part of 'upload_video_bloc.dart';

abstract class UploadVideoState extends Equatable {
  const UploadVideoState();

  @override
  List<Object?> get props => [];
}


//썸네일 초기화 성공
class UploadVideoInitial extends UploadVideoState {

  const UploadVideoInitial();

  @override
  List<Object?> get props => [];
}

//썸네일 초기화 성공
class UploadVideoInitialSuccess extends UploadVideoState {
  final String? thumbnailPath;

  const UploadVideoInitialSuccess({
    this.thumbnailPath,
  });

  @override
  List<Object?> get props => [thumbnailPath];
}

//썸네일 초기화 로딩
class UploadVideoInitialLoading extends UploadVideoState {}


//썸네일 초기화 로딩 실패
class UploadVideoInitialError extends UploadVideoState {
  final String error;

  const UploadVideoInitialError({
    required this.error,
  });

  @override
  List<Object?> get props => [error];
}



//업로드 로딩
class UploadVideoLoading extends UploadVideoState {

  const UploadVideoLoading();

  @override
  List<Object?> get props => [];
}


//업로드 성공
class UploadVideoSuccess extends UploadVideoState {
  final String message;

  const UploadVideoSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}


//업로드 실패
class UploadVideoError extends UploadVideoState {
  final String? description;
  final String error;

  const UploadVideoError({
    this.description,
    required this.error,
  });

  @override
  List<Object?> get props => [description, error];
}

