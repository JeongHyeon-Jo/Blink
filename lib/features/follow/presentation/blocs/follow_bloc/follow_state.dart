import 'package:blink/features/follow/data/models/follow_model.dart';

abstract class FollowState {}

class FollowLoading extends FollowState {}

class FollowLoaded extends FollowState {
  final List<FollowModel> followList;
  final List<String> followingList;

  FollowLoaded({required this.followList, required this.followingList});
}

class FollowError extends FollowState {
  final String message;

  FollowError(this.message);
}
