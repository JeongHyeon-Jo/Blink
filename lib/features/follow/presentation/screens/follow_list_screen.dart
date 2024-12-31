import 'package:blink/features/follow/domain/repositories/follow_repository.dart';
import 'package:blink/features/user/data/models/user_model.dart';
import 'package:blink/features/user/domain/repositories/auth_repository.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:blink/core/theme/colors.dart';
import 'package:blink/features/follow/presentation/blocs/follow_bloc/follow_bloc.dart';
import 'package:blink/features/follow/presentation/blocs/follow_bloc/follow_event.dart';
import 'package:blink/features/follow/presentation/blocs/follow_bloc/follow_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class FollowListScreen extends StatelessWidget {
  final String type;
  final String userId;

  const FollowListScreen({Key? key, required this.type, required this.userId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FollowBloc(
        followRepository: FollowRepository(),
        authRepository: AuthRepository(),
      )..add(LoadFollowList(userId, type)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            type == 'following' ? '팔로잉' : '팔로워',
            style: TextStyle(color: AppColors.textWhite),
          ),
          backgroundColor: AppColors.backgroundBlackColor,
          iconTheme: const IconThemeData(color: AppColors.iconWhite),
        ),
        body: BlocBuilder<FollowBloc, FollowState>(
          builder: (context, state) {
            if (state is FollowLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is FollowError) {
              return Center(
                child: Text(
                  state.message,
                  style: TextStyle(color: AppColors.textGrey),
                ),
              );
            } else if (state is FollowLoaded) {
              return ListView.builder(
                itemCount: state.followList.length,
                itemBuilder: (context, index) {
                  final followModel = state.followList[index];
                  final targetUserId = type == 'following'
                      ? followModel.followedId
                      : followModel.followerId;

                  return FutureBuilder<UserModel?>(
                    future: AuthRepository().getUserDataWithUserId(targetUserId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return CircularProgressIndicator();
                      }

                      final user = snapshot.data!;
                      final isFollowing =
                          state.followingList.contains(targetUserId);

                      return _buildFollowItem(
                        user,
                        followModel.createdAt,
                        context,
                        isFollowing,
                        () => context.read<FollowBloc>().add(
                              ToggleFollow(userId, targetUserId),
                            ),
                      );
                    },
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildFollowItem(
    UserModel user,
    DateTime createdAt,
    BuildContext context,
    bool isFollowing,
    VoidCallback onToggleFollow,
  ) {
    final profileImageUrl =
        user.profileImageUrl ?? 'assets/images/default_profile.png';
    final nickname = user.nickname;

    final formattedDate =
        DateFormat('yy/MM/dd a h시 m분', 'ko_KR').format(createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundLightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.backgroundDarkGrey,
          child: ClipOval(
            child: profileImageUrl.startsWith('http')
                ? CachedNetworkImage(
                    imageUrl: profileImageUrl,
                    placeholder: (context, url) =>
                        CircularProgressIndicator(color: AppColors.primaryColor),
                    errorWidget: (context, url, error) =>
                        Image.asset('assets/images/default_profile.png'),
                    fit: BoxFit.cover,
                    width: 50,
                    height: 50,
                  )
                : Image.asset(
                    profileImageUrl,
                    fit: BoxFit.cover,
                    width: 50,
                    height: 50,
                  ),
          ),
        ),
        title: Text(
          '@$nickname',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
        subtitle: Text(
          '팔로우한 날짜\n$formattedDate',
          style: TextStyle(color: AppColors.textGrey),
        ),
        trailing: ElevatedButton(
          onPressed: onToggleFollow,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isFollowing ? AppColors.primaryLightColor : AppColors.primaryColor,
            foregroundColor: AppColors.textWhite,
          ),
          child: Text(isFollowing ? '언팔로우' : '팔로우'),
        ),
        onTap: () {
          GoRouter.of(context).push('/profile/${user.id}');
        },
      ),
    );
  }
}
