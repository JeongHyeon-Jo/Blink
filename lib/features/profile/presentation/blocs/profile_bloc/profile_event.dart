import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  final String userId;

  const LoadProfile({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class LoadCurrentUserId extends ProfileEvent {}

class ToggleFollowEvent extends ProfileEvent {
  final String currentUserId;
  final String targetUserId;
  final bool isFollowing;

  ToggleFollowEvent({
    required this.currentUserId,
    required this.targetUserId,
    required this.isFollowing,
  });
}

