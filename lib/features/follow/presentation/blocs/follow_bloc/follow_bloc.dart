import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blink/features/follow/domain/repositories/follow_repository.dart';
import 'package:blink/features/user/domain/repositories/auth_repository.dart';
import 'follow_event.dart';
import 'follow_state.dart';

class FollowBloc extends Bloc<FollowEvent, FollowState> {
  final FollowRepository followRepository;
  final AuthRepository authRepository;

  FollowBloc({required this.followRepository, required this.authRepository})
      : super(FollowLoading()) {
    on<LoadFollowList>(_onLoadFollowList);
    on<ToggleFollow>(_onToggleFollow);
  }

  Future<void> _onLoadFollowList(
    LoadFollowList event,
    Emitter<FollowState> emit,
  ) async {
    emit(FollowLoading());
    try {
      final followList =
          await followRepository.getFollowList(event.userId, event.type);
      final currentUser =
          await authRepository.getUserDataWithUserId(event.userId);

      if (currentUser != null) {
        emit(FollowLoaded(
          followList: followList,
          followingList: currentUser.followingList ?? [],
        ));
      }
    } catch (e) {
      emit(FollowError('팔로우 목록을 불러오는 데 실패했습니다: $e'));
    }
  }

  Future<void> _onToggleFollow(
    ToggleFollow event,
    Emitter<FollowState> emit,
  ) async {
    if (state is FollowLoaded) {
      final currentState = state as FollowLoaded;

      try {
        if (currentState.followingList.contains(event.targetUserId)) {
          await followRepository.unfollow(event.currentUserId, event.targetUserId);
        } else {
          await followRepository.follow(event.currentUserId, event.targetUserId);
        }

        final currentUser =
            await authRepository.getUserDataWithUserId(event.currentUserId);

        emit(FollowLoaded(
          followList: currentState.followList,
          followingList: currentUser?.followingList ?? [],
        ));
      } catch (e) {
        emit(FollowError('팔로우/언팔로우 중 오류 발생: $e'));
      }
    }
  }
}
