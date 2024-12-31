import 'package:blink/core/theme/colors.dart';
import 'package:blink/features/follow/domain/repositories/follow_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:blink/features/user/domain/repositories/auth_repository.dart';
import 'package:blink/features/video/data/repositories/video_repository_impl.dart';
import 'package:blink/features/profile/presentation/blocs/profile_bloc/profile_bloc.dart';
import 'package:blink/features/profile/presentation/blocs/profile_bloc/profile_event.dart';
import 'package:blink/features/profile/presentation/blocs/profile_bloc/profile_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:blink/core/utils/blink_sharedpreference.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileBloc _profileBloc;
  final AuthRepository _authRepository = AuthRepository();
  final BlinkSharedPreference _sharedPreference = BlinkSharedPreference();
  bool isFollowing = false;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeBloc();
    _checkIfFollowing();
  }

  void _initializeBloc() {
    _profileBloc = ProfileBloc(
      authRepository: _authRepository,
      videoRepository: VideoRepositoryImpl(),
    )..add(LoadProfile(userId: widget.userId));
  }

  void _openLink(String link) async {
    if (!link.startsWith('http://') && !link.startsWith('https://')) {
      link = 'https://$link';
    }
    final Uri url = Uri.parse(link);
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
    } else {
      debugPrint('Could not launch $link');
    }
  }

  Future<void> _checkIfFollowing() async {
    final currentUserId = await _sharedPreference.getCurrentUserId();
    final isFollowed = await FollowRepository().isFollowing(currentUserId, widget.userId);
    setState(() {
      isFollowing = isFollowed;
    });
  }

  Future<void> _toggleFollow() async {
    final currentUserId = await _sharedPreference.getCurrentUserId();
    try {
      if (isFollowing) {
        await FollowRepository().unfollow(currentUserId, widget.userId);
      } else {
        await FollowRepository().follow(currentUserId, widget.userId);
      }
      setState(() {
        isFollowing = !isFollowing;
      });
    } catch (e) {
      print("팔로우/언팔로우 실패: $e");
    }
  }

  Future<void> _showLogoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "로그아웃",
          style: TextStyle(color: AppColors.textWhite),
        ),
        content: Text(
          "정말 로그아웃 하시겠습니까?",
          style: TextStyle(color: AppColors.textGrey),
        ),
        backgroundColor: AppColors.backgroundDarkGrey,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("아니요", style: TextStyle(color: AppColors.primaryLightColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("예", style: TextStyle(color: AppColors.primaryColor)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _authRepository.signOut();
      await _sharedPreference.clearPreference();

      context.go('/main-navigation/0');
    }
  }

  Widget _buildStatItem(String value, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: color)),
          SizedBox(height: 5.h),
          Text(label, style: TextStyle(fontSize: 12.sp, color: AppColors.textGrey)),
        ],
      ),
    );
  }

  Widget _buildVideoItem(String? imagePath, String title, String views) {
    final defaultImage = "assets/images/default_image.png";

    bool isValidUrl(String? url) {
      if (url == null || url.isEmpty) return false;
      final uri = Uri.tryParse(url);
      return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: isValidUrl(imagePath)
                ? CachedNetworkImage(
                    imageUrl: imagePath!,
                    placeholder: (context, url) =>
                        CircularProgressIndicator(color: AppColors.primaryColor),
                    errorWidget: (context, url, error) =>
                        Image.asset(defaultImage, fit: BoxFit.cover),
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    defaultImage,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryColor,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          views,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textWhite,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _profileBloc,
      child: Scaffold(
        backgroundColor: AppColors.backgroundBlackColor,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundBlackColor,
          title: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoaded) {
                return Text(
                  state.user.name,
                  style: TextStyle(fontSize: 18.sp, color: AppColors.textWhite),
                );
              }
              return Text(
                "프로필",
                style: TextStyle(fontSize: 18.sp, color: AppColors.textWhite),
              );
            },
          ),
          centerTitle: true,
          actions: [
            BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                if (currentUserId == widget.userId) {
                  return PopupMenuButton<String>(
                    color: AppColors.backgroundDarkGrey,
                    onSelected: (value) {
                      if (value == 'logout') {
                        _showLogoutDialog();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'logout',
                        child: Text(
                          "로그아웃",
                          style: TextStyle(color: AppColors.textWhite),
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: TextStyle(color: AppColors.textWhite),
                  ),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ProfileLoading) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              );
            } else if (state is ProfileLoaded) {
              final user = state.user;
              final videos = state.videos ?? [];

              return SingleChildScrollView(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 70.r,
                      backgroundColor: AppColors.backgroundDarkGrey,
                      child: ClipOval(
                        child: (user.profileImageUrl != null && user.profileImageUrl!.trim().isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: user.profileImageUrl!,
                                placeholder: (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Image.asset(
                                  "assets/images/default_profile.png",
                                  fit: BoxFit.cover,
                                  width: 140.r,
                                  height: 140.r,
                                ),
                                fit: BoxFit.cover,
                                width: 140.r,
                                height: 140.r,
                              )
                            : Image.asset(
                                "assets/images/default_profile.png",
                                fit: BoxFit.cover,
                                width: 140.r,
                                height: 140.r,
                              ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      "@${user.nickname}",
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatItem(
                          user.followingList?.length.toString() ?? "0",
                          "팔로잉",
                          AppColors.primaryColor,
                          () {
                            GoRouter.of(context).push(
                              '/follow_list',
                              extra: {'type': 'following', 'userId': user.id},
                            );
                          },
                        ),
                        SizedBox(width: 20.w),
                        _buildStatItem(
                          user.followerList?.length.toString() ?? "0",
                          "팔로워",
                          AppColors.primaryColor,
                          () {
                            GoRouter.of(context).push(
                              '/follow_list',
                              extra: {'type': 'follower', 'userId': user.id},
                            );
                          },
                        ),
                        SizedBox(width: 20.w),
                        _buildStatItem(
                          videos
                              .map((video) => video.likeList.length)
                              .fold(0, (a, b) => a + b)
                              .toString(),
                          "좋아요",
                          AppColors.primaryColor,
                          () {},
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (context, state) {
                        if (state is ProfileLoaded) {
                          final isCurrentUser = state.currentUserId == widget.userId;

                          if (isCurrentUser) {
                            return ElevatedButton(
                              onPressed: () async {
                                final updated = await GoRouter.of(context).push(
                                  '/profile_edit',
                                  extra: state.user,
                                );
                                if (updated == true) {
                                  context.read<ProfileBloc>().add(LoadProfile(userId: widget.userId));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryColor,
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: Text(
                                "프로필 편집",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.textWhite,
                                ),
                              ),
                            );
                          } else {
                            final isFollowing = state.isFollowing;

                            return ElevatedButton(
                              onPressed: () {
                                context.read<ProfileBloc>().add(
                                  ToggleFollowEvent(
                                    currentUserId: state.currentUserId,
                                    targetUserId: widget.userId,
                                    isFollowing: isFollowing,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowing
                                    ? AppColors.primaryLightColor
                                    : AppColors.primaryColor,
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              child: Text(
                                isFollowing ? "언팔로우" : "팔로우",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.textWhite,
                                ),
                              ),
                            );
                          }
                        } else if (state is ProfileLoading) {
                          return Center(
                            child: CircularProgressIndicator(color: AppColors.primaryColor),
                          );
                        } else if (state is ProfileError) {
                          return Center(
                            child: Text(
                              "프로필 로드 실패: ${state.message}",
                              style: TextStyle(color: AppColors.errorRed),
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),
                    SizedBox(height: 15.h),
                    if (user.introduction?.isNotEmpty == true)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Text(
                          user.introduction!,
                          style: TextStyle(fontSize: 14.sp, color: AppColors.textGrey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    SizedBox(height: 10.h),
                    if (user.linkList?.isNotEmpty == true)
                      Padding(
                      padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(
                            color: AppColors.primaryDarkColor,
                            width: 1.w,
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      final firstLink = user.linkList!.first;
                                      _openLink(firstLink);
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 5.h),
                                      child: Text(
                                        user.linkList!.first,
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: AppColors.secondaryColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                    color: AppColors.secondaryColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isExpanded = !isExpanded;
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (isExpanded)
                              Column(
                                children: user.linkList!.skip(1).map((link) {
                                  return Column(
                                    children: [
                                      Divider(
                                        color: AppColors.primaryDarkColor,
                                        thickness: 1.h,
                                        indent: 0.w,
                                        endIndent: 10.w,
                                      ),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: 10.h),
                                          child: GestureDetector(
                                            onTap: () {
                                              _openLink(link);
                                            },
                                            child: Text(
                                              link,
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: AppColors.secondaryColor,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Divider(color: AppColors.primaryDarkColor, thickness: 1.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Text(
                        "동영상",
                        style: TextStyle(fontSize: 16.sp, color: AppColors.textWhite),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10.w,
                        mainAxisSpacing: 10.h,
                      ),
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        final video = videos[index];
                        return _buildVideoItem(
                          video.thumbnailUrl,
                          video.title,
                          "조회수:${video.views}",
                        );
                      },
                    ),
                  ],
                ),
              );
            } else {
              return Center(
                child: Text(
                  '프로필을 불러오는 중입니다',
                  style: TextStyle(color: AppColors.textWhite),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

