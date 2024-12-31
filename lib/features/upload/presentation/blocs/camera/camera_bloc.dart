import 'package:blink/features/upload/domain/repositories/upload_repository.dart';
import 'package:blink/features/upload/presentation/blocs/camera/camera_event.dart';
import 'package:blink/features/upload/presentation/blocs/camera/camera_state.dart';
import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  CameraController? _cameraController;
  UploadRepository uploadRepository = UploadRepository();
  final ImagePicker _picker = ImagePicker();

  CameraBloc() : super(CameraInitial()) {
    on<InitializeCamera>(_onInitializeCamera);
    on<StartRecording>(_onStartRecording);
    on<StopRecording>(_onStopRecording);
    on<DisposeCamera>(_onDisposeCamera);
    on<PickVideoFromGallery>(_onPickVideoFromGallery);
  }

  Future<void> _onInitializeCamera(
    InitializeCamera event,
    Emitter<CameraState> emit,
  ) async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        emit(const CameraError("카메라를 사용할 수 없습니다. 실제 기기에서 테스트해주세요."));
        return;
      }

      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      emit(CameraInitialized(_cameraController!));
    } catch (e) {
      emit(CameraError(e.toString()));
    }
  }

  Future<void> _onStartRecording(
    StartRecording event,
    Emitter<CameraState> emit,
  ) async {
    if (_cameraController == null) return;

    try {
      await _cameraController!.startVideoRecording();
      emit(CameraRecording(_cameraController!));
    } catch (e) {
      emit(CameraError(e.toString()));
    }
  }

  Future<void> _onStopRecording(
    StopRecording event,
    Emitter<CameraState> emit,
  ) async {
    if (_cameraController == null) return;

    try {
      final XFile video = await _cameraController!.stopVideoRecording();
      emit(VideoSelected(video));
      // uploadRepository.uploadVideo(video);
      emit(CameraInitialized(_cameraController!));
      print('Video saved at: ${video.path}');
    } catch (e) {
      emit(CameraError(e.toString()));
    }
  }

  Future<void> _onDisposeCamera(
    DisposeCamera event,
    Emitter<CameraState> emit,
  ) async {
    await _cameraController?.dispose();
    _cameraController = null;
    emit(CameraInitial());
  }

  Future<void> _onPickVideoFromGallery(
    PickVideoFromGallery event,
    Emitter<CameraState> emit,
  ) async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10), // 필요에 따라 조정
      );

      if (video != null) {
        // uploadRepository.uploadVideo(video);
        emit(VideoSelected(video));
        emit(CameraInitialized(_cameraController!));
      }
    } catch (e) {
      emit(CameraError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _cameraController?.dispose();
    return super.close();
  }
}
