import 'package:blink/features/search/data/datasources/local/search_local_datasource.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:rxdart/rxdart.dart';
import 'package:blink/core/theme/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

final BehaviorSubject<List<dynamic>> _popularStreamController = BehaviorSubject<List<dynamic>>();

class SearchedScreen extends StatefulWidget {
  final String query;

  const SearchedScreen({Key? key, required this.query}) : super(key: key);

  @override
  _SearchedScreenState createState() => _SearchedScreenState();
}

class _SearchedScreenState extends State<SearchedScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SearchLocalDataSource localDataSource = SearchLocalDataSource();
  late String currentQuery;

  @override
  void initState() {
    super.initState();
    currentQuery = widget.query;
    _searchController.text = currentQuery;
    _initializePopularStream(currentQuery);

    _saveSearchQuery(currentQuery);
  }

  void _initializePopularStream(String query) {
    final popularStream = Rx.combineLatest3(
      FirebaseFirestore.instance.collection('users').snapshots(),
      FirebaseFirestore.instance.collection('videos').snapshots(),
      FirebaseFirestore.instance.collection('hashtags').snapshots(),
      (QuerySnapshot userSnapshot, QuerySnapshot videoSnapshot, QuerySnapshot hashtagSnapshot) {
        // 사용자 검색
        final users = userSnapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['name'].toString().contains(query) ||
              data['nickname'].toString().contains(query) ||
              data['email'].toString().contains(query);
        }).map((doc) => {'type': 'user', 'data': doc.data()}).toList();

        // 동영상 검색
        final videos = videoSnapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final uploaderId = data['uploader_id'] ?? '';
          final uploader = userSnapshot.docs.cast<QueryDocumentSnapshot<Map<String, dynamic>>?>().firstWhere(
            (userDoc) => userDoc?.id == uploaderId,
            orElse: () => null,
          );

          if (uploader != null) {
            final uploaderData = uploader.data() as Map<String, dynamic>;
            return uploaderData['name'].toString().contains(query) ||
                uploaderData['nickname'].toString().contains(query) ||
                data['title'].toString().contains(query) ||
                data['description'].toString().contains(query);
          }

          return data['title'].toString().contains(query) || 
                data['description'].toString().contains(query);
        }).map((doc) => {'type': 'video', 'data': doc.data()}).toList();

        // 해시태그 검색
        final hashtags = hashtagSnapshot.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['tag'].toString().contains(query);
        }).map((doc) => {'type': 'hashtag', 'data': doc.data()}).toList();

        return [...users, ...videos, ...hashtags];
      },
    );

    popularStream.listen((data) {
      _popularStreamController.add(data);
    });
  }

  void _onSearch(String query) async {
    if (query.isNotEmpty) {
      setState(() {
        currentQuery = query;
        _initializePopularStream(query);
      });
    }

    await _saveSearchQuery(query);
  }

  Future<void> _saveSearchQuery(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final searches = await localDataSource.fetchRecentSearches();

    if (searches.contains(query)) {
      searches.remove(query);
    }
    searches.insert(0, query);

    if (searches.length > 5) {
      searches.removeLast();
    }

    await prefs.setStringList(SearchLocalDataSource.recentSearchesKey, searches);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.backgroundBlackColor,
          title: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '검색어를 입력하세요',
              hintStyle: TextStyle(fontSize: 18.sp, color: AppColors.textGrey),
              filled: true,
              fillColor: AppColors.backgroundDarkGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: 12.h,
                horizontal: 10.w,
              ),
            ),
            style: TextStyle(fontSize: 18.sp, color: AppColors.textWhite),
            onSubmitted: _onSearch,
          ),
          actions: [
            TextButton(
              child: Text(
                '검색',
                style: TextStyle(color: AppColors.primaryColor, fontSize: 16.sp),
              ),
              onPressed: () {
                final query = _searchController.text.trim();
                _onSearch(query);
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.primaryColor,
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: AppColors.textGrey,
            tabs: [
              Tab(text: "인기", height: 40.h),
              Tab(text: "사용자", height: 40.h),
              Tab(text: "동영상", height: 40.h),
              Tab(text: "해시태그", height: 40.h),
            ],
          ),
        ),
        body: Container(
          color: AppColors.backgroundBlackColor,
          child: Column(
            children: [
              StreamBuilder<List<dynamic>>(
                stream: _popularStreamController.stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primaryColor),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildPopularContent(),
                    _buildUserContent(),
                    _buildVideoContent(),
                    _buildHashtagContent(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic> items, VoidCallback onMoreTap) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textWhite),
              ),
              TextButton(
                onPressed: onMoreTap,
                child: Text("더보기", style: TextStyle(fontSize: 14.sp, color: AppColors.primaryLightColor)),
              ),
            ],
          ),
        ),
        ...items.map((item) {
          if (item['type'] == 'user') return _buildUserItem(item['data']);
          if (item['type'] == 'video') return _buildVideoItem(item['data']);
          if (item['type'] == 'hashtag') return _buildHashtagItem(item['data']);
          return const SizedBox.shrink();
        }).toList(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Divider(
            height: 20.h,
            thickness: 1.h,
            color: AppColors.primaryDarkColor,
          ),
        ),
      ],
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    final profileImageUrl = user['profile_image_url'] as String?;

    return ListTile(
      leading: CircleAvatar(
        radius: 20.r,
        child: CachedNetworkImage(
          imageUrl: profileImageUrl?.isNotEmpty == true ? profileImageUrl! : "",
          placeholder: (context, url) => Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: AppColors.backgroundDarkGrey,
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 2.w,
              color: AppColors.primaryColor,
            ),
          ),
          errorWidget: (context, url, error) => CircleAvatar(
            radius: 20.r,
            backgroundImage: const AssetImage("assets/images/default_profile.png"),
          ),
          imageBuilder: (context, imageProvider) => CircleAvatar(
            radius: 20.r,
            backgroundImage: imageProvider,
          ),
        ),
      ),
      title: Text(
        user['name'] ?? 'Unknown',
        style: TextStyle(color: AppColors.textWhite),
      ),
      subtitle: Text(
        '@' + (user['nickname'] ?? 'No username'),
        style: TextStyle(color: AppColors.textGrey),
      ),
      onTap: () {
        final userId = user['id'];
        if (userId != null) {
          GoRouter.of(context).push('/profile/$userId');
        } else {
          debugPrint("유효하지 않은 사용자 ID");
        }
      },
    );
  }

  Widget _buildVideoItem(Map<String, dynamic> video) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(video['uploader_id']).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(
            title: Text(
              'Loading...',
              style: TextStyle(color: AppColors.textGrey),
            ),
          );
        }

        final uploaderData = snapshot.data?.data() as Map<String, dynamic>?;

        return ListTile(
          leading: Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: CachedNetworkImage(
                imageUrl: video['thumbnailUrl']?.isNotEmpty == true ? video['thumbnailUrl']! : "",
                placeholder: (context, url) => Container(
                  color: AppColors.backgroundDarkGrey,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Image.asset(
                  'assets/images/default_image.png',
                  fit: BoxFit.cover,
                ),
                imageBuilder: (context, imageProvider) => Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            video['title'] ?? 'No title',
            style: TextStyle(color: AppColors.textWhite),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            video['description'] ?? 'No description',
            style: TextStyle(color: AppColors.textGrey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: uploaderData != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tv,
                    color: AppColors.primaryLightColor,
                    size: 18.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${uploaderData['name'] ?? 'Unknown'}',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 17.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : null,
        );
      },
    );
  }

  Widget _buildHashtagItem(Map<String, dynamic> hashtag) {
    return ListTile(
      leading: Icon(Icons.tag, size: 20.sp, color: AppColors.primaryLightColor),
      title: Text(
        hashtag['tag'],
        style: TextStyle(fontSize: 14.sp, color: AppColors.textWhite),
      ),
    );
  }

  Widget _buildPopularContent() {
    return StreamBuilder<List<dynamic>>(
      stream: _popularStreamController.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final combinedResults = snapshot.data!;
        final users = combinedResults.where((item) => item['type'] == 'user').take(4).toList();
        final videos = combinedResults.where((item) => item['type'] == 'video').take(4).toList();
        final hashtags = combinedResults.where((item) => item['type'] == 'hashtag').take(4).toList();

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildSection("사용자", users, () => DefaultTabController.of(context)?.animateTo(1)),
              _buildSection("동영상", videos, () => DefaultTabController.of(context)?.animateTo(2)),
              _buildSection("해시태그", hashtags, () => DefaultTabController.of(context)?.animateTo(3)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserContent() {
    return _buildStreamList('users', ['name', 'email'], _buildUserItem);
  }

  Widget _buildVideoContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('videos').snapshots(),
      builder: (context, videoSnapshot) {
        if (!videoSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final videoDocs = videoSnapshot.data!.docs.where((videoDoc) {
              final videoData = videoDoc.data() as Map<String, dynamic>;
              final uploaderId = videoData['uploader_id'] ?? '';
              final uploader = userSnapshot.data!.docs
                  .cast<QueryDocumentSnapshot<Map<String, dynamic>>?>()
                  .firstWhere(
                    (userDoc) => userDoc?.id == uploaderId,
                    orElse: () => null,
                  );

              if (uploader != null) {
                final uploaderData = uploader.data()!;
                return uploaderData['name'].toString().contains(currentQuery) ||
                    uploaderData['nickname'].toString().contains(currentQuery) ||
                    videoData['title'].toString().contains(currentQuery) ||
                    videoData['description'].toString().contains(currentQuery);
              }

              return videoData['title'].toString().contains(currentQuery) ||
                  videoData['description'].toString().contains(currentQuery);
            }).toList();

            return ListView.builder(
              itemCount: videoDocs.length,
              itemBuilder: (context, index) {
                final videoData = videoDocs[index].data() as Map<String, dynamic>;
                return _buildVideoItem(videoData);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHashtagContent() {
    return _buildStreamList('hashtags', ['tag'], _buildHashtagItem);
  }

  Widget _buildStreamList(String collection, List<String> fields, Function itemBuilder) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return fields.any((field) => data[field].toString().contains(currentQuery));
        }).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: results.length,
          itemBuilder: (context, index) {
            return itemBuilder(results[index].data() as Map<String, dynamic>);
          },
        );
      },
    );
  }
}
