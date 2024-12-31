import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blink/features/user/domain/entities/user_entity.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String nickname;
  final String? profileImageUrl;
  final List<String>? followingList;
  final List<String>? followerList;
  final List<String>? watchList;
  final String? recommendId;
  final String? pushToken;
  final int? point;
  final String? introduction;
  final List<String>? linkList;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int basket;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.nickname,
    this.profileImageUrl,
    this.followingList,
    this.followerList,
    this.watchList,
    this.recommendId,
    this.pushToken,
    this.point,
    this.introduction,
    this.linkList,
    required this.createdAt,
    required this.updatedAt,
    this.basket = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      nickname: json['nickname'] as String? ?? 'Unknown',
      profileImageUrl: json['profile_image_url'] as String?,
      followingList: (json['following_list'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      followerList: (json['follower_list'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      watchList: (json['watch_list'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      recommendId: json['recommend_id'] as String?,
      pushToken: json['push_token'] as String?,
      point: json['point'] as int? ?? 0,
      introduction: json['introduction'] as String?,
      linkList: (json['link_list'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: (json['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      basket: json['basket'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'nickname': nickname,
      'profile_image_url': profileImageUrl,
      'following_list': followingList ?? [],
      'follower_list': followerList ?? [],
      'watch_list': watchList ?? [],
      'recommend_id': recommendId,
      'push_token': pushToken,
      'point': point ?? 0,
      'introduction': introduction,
      'link_list': linkList ?? [],
      'created_at': createdAt != null ? Timestamp.fromDate(createdAt) : null,
      'updated_at': updatedAt != null ? Timestamp.fromDate(updatedAt) : null,
      'basket': basket,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? nickname,
    String? profileImageUrl,
    List<String>? followingList,
    List<String>? followerList,
    List<String>? watchList,
    String? recommendId,
    String? pushToken,
    int? point,
    String? introduction,
    List<String>? linkList,
    DateTime? createdAt,
    DateTime? updatedAt,
    int basket = 0,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      followingList: followingList ?? this.followingList,
      followerList: followerList ?? this.followerList,
      watchList: watchList ?? this.watchList,
      recommendId: recommendId ?? this.recommendId,
      pushToken: pushToken ?? this.pushToken,
      point: point ?? this.point,
      introduction: introduction ?? this.introduction,
      linkList: linkList ?? this.linkList,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      basket: basket ?? this.basket,
    );
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      nickname: nickname,
      email: email,
      profileImageUrl: profileImageUrl,
      followingList: followingList ?? [],
      followerList: followerList ?? [],
      introduction: introduction ?? '',
      linkList: linkList ?? [],
    );
  }

  UserModel addPoints(int pointsToAdd) {
    return copyWith(point: (point ?? 0) + pointsToAdd);
  }
}
