import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blink/features/search/data/datasources/local/search_local_datasource.dart';
import 'package:blink/core/theme/colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
  final SearchLocalDataSource localDataSource = SearchLocalDataSource();
  List<String> recentSearches = [];
  List<String> trendingSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _loadTrendingSearches();
  }

  Future<void> _loadRecentSearches() async {
    final searches = await localDataSource.fetchRecentSearches();
    setState(() {
      recentSearches = searches;
    });
  }

  Future<void> _loadTrendingSearches() async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      final querySnapshot = await FirebaseFirestore.instance
          .collection('searches')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .orderBy('timestamp', descending: true)
          .get();

      final searchCounts = <String, int>{};

      for (var doc in querySnapshot.docs) {
        final query = doc['query'] as String;
        if (searchCounts.containsKey(query)) {
          searchCounts[query] = searchCounts[query]! + 1;
        } else {
          searchCounts[query] = 1;
        }
      }

      final sortedSearches = searchCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        trendingSearches = sortedSearches.take(10).map((e) => e.key).toList();
      });

      debugPrint("추천 검색어: $trendingSearches");
    } catch (e) {
      debugPrint("추천 검색어 로드 실패: $e");
    }
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
    await _loadRecentSearches();
  }

  Future<void> _deleteSearchQuery(String query) async {
    await localDataSource.deleteSearchQuery(query);
    await _loadRecentSearches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlackColor,
        title: TextField(
          controller: searchController,
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
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final query = searchController.text.trim();
              if (query.isNotEmpty) {
                await _saveSearchQuery(query);
                context.push('/search/results/$query');
              }
            },
            child: Text(
              '검색',
              style: TextStyle(color: AppColors.primaryColor, fontSize: 16.sp),
            ),
          ),
        ],
      ),
      body: Container(
        color: AppColors.backgroundBlackColor,
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recentSearches.isNotEmpty) ...[
                  Text(
                    "최근 검색어",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ListView.builder(
                    itemCount: recentSearches.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final search = recentSearches[index];
                      return ListTile(
                        title: Text(
                          search,
                          style: TextStyle(fontSize: 14.sp, color: AppColors.textWhite),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.close, size: 18.sp, color: AppColors.iconGrey),
                          onPressed: () {
                            _deleteSearchQuery(search);
                          },
                        ),
                        onTap: () {
                          _saveSearchQuery(search);
                          context.push('/search/results/$search');
                        },
                      );
                    },
                  ),
                ],
                if (recentSearches.isNotEmpty && trendingSearches.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Divider(
                    color: AppColors.primaryDarkColor,
                    thickness: 1.h,
                  ),
                  SizedBox(height: 16.h),
                ],
                if (trendingSearches.isNotEmpty) ...[
                  Text(
                    "추천 검색어",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textWhite,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: trendingSearches.map((search) {
                      return ElevatedButton(
                        onPressed: () {
                          _saveSearchQuery(search);
                          context.push('/search/results/$search');
                        },
                        child: Text(
                          search,
                          style: TextStyle(fontSize: 14.sp, color: AppColors.textWhite),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
