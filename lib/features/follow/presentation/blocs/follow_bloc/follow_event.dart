abstract class FollowEvent {}

class LoadFollowList extends FollowEvent {
  final String userId;
  final String type; // 'following' or 'follower'

  LoadFollowList(this.userId, this.type);
}

class ToggleFollow extends FollowEvent {
  final String currentUserId;
  final String targetUserId;

  ToggleFollow(this.currentUserId, this.targetUserId);
}
