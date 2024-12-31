class UserEntity {
  final String id;
  final String name;
  final String nickname;
  final String email;
  final String? profileImageUrl;
  final List<String>? followingList;
  final List<String>? followerList;
  final String? introduction;
  final List<String>? linkList;

  const UserEntity({
    required this.id,
    required this.name,
    required this.nickname,
    required this.email,
    this.profileImageUrl,
    this.followingList,
    this.followerList,
    this.introduction,
    this.linkList,
  });
}
