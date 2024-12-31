import 'package:blink/features/follow/domain/repositories/follow_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:blink/core/utils/blink_sharedpreference.dart';
import 'package:blink/features/user/domain/repositories/auth_repository.dart';
import 'package:blink/features/video/domain/repositories/video_repository.dart';
import 'package:blink/features/profile/presentation/blocs/profile_bloc/profile_event.dart';
import 'package:blink/features/profile/presentation/blocs/profile_bloc/profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthRepository authRepository;
  final VideoRepository videoRepository;
  final BlinkSharedPreference _sharedPreference = BlinkSharedPreference();

  ProfileBloc({
    required this.authRepository,
    required this.videoRepository,
  }) : super(ProfileInitial()) {
    // Load Profile 이벤트 처리
    on<LoadProfile>((event, emit) async {
      emit(ProfileLoading());
      try {
        final userModel =
            await authRepository.getUserDataWithUserId(event.userId);
        final videos = await videoRepository.getVideosByUserId(event.userId);

        if (userModel == null) {
          throw Exception("UserModel이 null입니다. 유효한 사용자 ID를 전달했는지 확인하세요.");
        }

        final currentUserId = await _sharedPreference.getCurrentUserId();
        final isFollowing = await FollowRepository()
            .isFollowing(currentUserId!, event.userId);

        emit(ProfileLoaded(
          user: userModel.toEntity(),
          videos: videos,
          isFollowing: isFollowing,
          currentUserId: currentUserId,
        ));
      } catch (e) {
        emit(ProfileError(message: e.toString()));
      }
    });

    on<LoadCurrentUserId>((event, emit) async {
      final currentUserId = await _sharedPreference.getCurrentUserId();
      final currentState = state;

      if (currentState is ProfileLoaded) {
        emit(ProfileWithCurrentUser(
          user: currentState.user,
          videos: currentState.videos,
          currentUserId: currentUserId!,
          isFollowing: currentState.isFollowing,
        ));
      }
    });

    // Toggle Follow 이벤트 처리
    on<ToggleFollowEvent>((event, emit) async {
      try {
        // 팔로우/언팔로우 처리
        if (event.isFollowing) {
          await FollowRepository().unfollow(event.currentUserId, event.targetUserId);
        } else {
          await FollowRepository().follow(event.currentUserId, event.targetUserId);
        }

        // 사용자 데이터 및 팔로우 상태 업데이트
        final updatedUser = await authRepository.getUserDataWithUserId(event.targetUserId);
        final isNowFollowing = !event.isFollowing;

        if (updatedUser == null) {
          emit(ProfileError(message: "사용자를 찾을 수 없습니다."));
          return;
        }

        if (state is ProfileLoaded) {
          emit(ProfileLoaded(
            user: updatedUser.toEntity(),
            videos: (state as ProfileLoaded).videos,
            isFollowing: isNowFollowing,
            currentUserId: event.currentUserId,
          ));
        }
      } catch (e) {
        emit(ProfileError(message: e.toString()));
      }
    });
  }
}
