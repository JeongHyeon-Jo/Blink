import 'dart:io';

import 'package:blink/core/theme/colors.dart';
import 'package:blink/features/upload/data/models/hashtag_model.dart';
import 'package:blink/features/upload/presentation/blocs/upload/upload_video_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class UploadDetailScreen extends StatefulWidget {
  final String videoPath;
  final String thumbnailPath;

  const UploadDetailScreen({super.key, required this.videoPath, required this.thumbnailPath});

  @override
  State<UploadDetailScreen> createState() => _UploadDetailScreenState();
}

class _UploadDetailScreenState extends State<UploadDetailScreen> {
  late final TextEditingController _contentController;
  late final TextEditingController _titleController;
  final _formKey = GlobalKey<FormState>();

  // 카테고리 리스트 추가
  final List<String> _categories = [
    '일상',
    '게임',
    '음악',
    '댄스',
    '요리',
    '스포츠',
    '교육',
    '동물',
    '기타'
  ];
  String _selectedCategory = '카테고리를 선택해주세요'; // 기본값
  // _UploadDetailScreenState에 해시태그 관리를 위한 상태 추가
  List<HashtagModel> _searchResults = []; // 검색 결과
  List<String> _hashtags = []; // 선택된 해시태그들
  late TextEditingController _hashtagController;

  @override
  void initState() {
    _contentController = TextEditingController();
    _titleController = TextEditingController();
    _hashtagController = TextEditingController();
    _contentController.addListener(_extractHashtagsFromContent);
    context.read<UploadVideoBloc>().add(
        InitializeVideo(videoPath: widget.videoPath));
    print("upload 초기화");
    super.initState();
  }

  @override
  void dispose() {
    _contentController.removeListener(_extractHashtagsFromContent);
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UploadVideoBloc, UploadVideoState>(
      listener: (context, state) {
        if (state is UploadVideoSuccess) {
          showUploadSuccessDialog(context);
        } else if (state is UploadVideoError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error ?? '업로드 실패')),
          );
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    context.pop();
                    context.pop();
                  },
                ),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.all(16.w),
                              child: TextFormField(
                                controller: _titleController,
                                maxLines: 1,
                                decoration: InputDecoration(
                                  hintText: '제목을 입력하세요...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '제목을 입력해주세요';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    margin: EdgeInsets.all(16.w),
                                    child: TextFormField(
                                      controller: _contentController,
                                      maxLines: 8,
                                      decoration: InputDecoration(
                                        hintText: '설명을 추가하세요...',
                                        hintStyle: TextStyle(
                                            color: Colors.grey),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              8.r),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return '설명을 입력해주세요';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                                _buildThumbnailPreview(context),
                              ],
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '카테고리',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12.w),
                                    width: double.infinity, // 컨테이너의 전체 너비 설정
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: PopupMenuButton<String>(
                                      initialValue: _selectedCategory,
                                      constraints: BoxConstraints(
                                        minWidth: MediaQuery
                                            .of(context)
                                            .size
                                            .width - 32.w,
                                        // 팝업 메뉴의 너비 설정 (화면 너비 - 좌우 패딩)
                                        maxWidth: MediaQuery
                                            .of(context)
                                            .size
                                            .width - 32.w,
                                      ),
                                      onSelected: (String value) {
                                        setState(() {
                                          _selectedCategory = value;
                                        });
                                      },
                                      offset: Offset(0, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            8.r),
                                      ),
                                      itemBuilder: (BuildContext context) {
                                        return _categories.map((String value) {
                                          return PopupMenuItem<String>(
                                            value: value,
                                            child: Container(
                                              width: double.infinity,
                                              // PopupMenuItem 내부 컨테이너의 너비를 최대로
                                              child: Text(value),
                                            ),
                                          );
                                        }).toList();
                                      },
                                      child: Container(
                                        height: 48.h,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment
                                              .spaceBetween,
                                          children: [
                                            Text(
                                              _selectedCategory,
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                            Icon(Icons.arrow_drop_down),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _showHashtagBottomSheet();
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.0.w, vertical: 10.h),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    '# 해시태그',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppColors.primaryColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              printDetailedHashtags();
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              backgroundColor: AppColors.primaryLightColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Text(
                              '임시 저장',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              if (!_categories.contains(_selectedCategory)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '유효하지 않은 카테고리입니다. 다시 선택해주세요.'),
                                    behavior: SnackBarBehavior.floating,
                                    // 플로팅 스타일
                                    duration: Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: '확인',
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .hideCurrentSnackBar();
                                      },
                                    ),
                                  ),
                                );
                                return;
                              }
                              if (_formKey.currentState!.validate() &&
                                  _categories.contains(_selectedCategory)) {
                                context.read<UploadVideoBloc>().add(
                                    UploadVideo(
                                        videoPath: widget.videoPath,
                                        description: _contentController.text,
                                        thumbnailImage: widget.thumbnailPath,
                                        videoTitle: _titleController.text,
                                        category: _selectedCategory,
                                        hashTags: _hashtags
                                    )
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              backgroundColor: AppColors.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Text(
                              '게시',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (state is UploadVideoLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  _buildThumbnailPreview(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 16.h, 16.w, 16.h),
      width: 100.w,
      height: 200.h,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Stack(
        children: [
          widget.thumbnailPath == "" ? // 썸네일 없을 경우 로고
          ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.asset(
                'assets/images/blink_logo.png',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.fill,
              )
          ) :
          ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.file(
                File(widget.thumbnailPath),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              )
          ),
          Positioned(
            top: 4.h,
            right: 6.w,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8.w,
                vertical: 4.h,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                '미리 보기',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showUploadSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // 바깥 영역 터치로 닫기 방지
      builder: (context) {
        return AlertDialog(
          title: Text('알림'),
          content: Text('영상이 성공적으로 업로드되었습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                context.pop(); // 알림창 닫기
                context.go('/main-navigation/0');
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Future<List<HashtagModel>> searchHashtags(String query) async {
    if (query.isEmpty) return [];

    final result = await FirebaseFirestore.instance
        .collection('hashtags')
        .where('query', isGreaterThanOrEqualTo: query)
        .where('query', isLessThanOrEqualTo: '${query}\uf8ff')
        .orderBy('query')
        .limit(10) // 최대 10개만 가져오기
        .get();

    return result.docs
        .map((doc) =>
        HashtagModel(
          query: doc['query'] ?? '',
          count: doc['count'] ?? 0,
        ))
        .toList();
  }

  void _showHashtagBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final TextEditingController localHashtagController = TextEditingController();
        List<HashtagModel> localSearchResults = [];

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Column(
                children: [
                  SizedBox(height: 8.h),
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: localHashtagController,
                            decoration: InputDecoration(
                              hintText: '해시태그 입력 (예: #일상)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        ElevatedButton(
                          onPressed: () async {
                            String tag = localHashtagController.text.trim();
                            if (tag.isNotEmpty) {
                              if (tag.startsWith('#')) {
                                tag = tag.substring(1);
                              }
                              final results = await searchHashtags(tag);
                              setModalState(() {
                                if (results.isEmpty) {
                                  // 검색 결과가 없을 경우, 새로운 해시태그 생성
                                  localSearchResults = [
                                    HashtagModel(
                                      query: tag,
                                      count: 0, // 새로운 해시태그이므로 count는 0으로 시작
                                    )
                                  ];
                                } else {
                                  localSearchResults = results;
                                }
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text('검색'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: localSearchResults.length,
                      itemBuilder: (context, index) {
                        final hashtag = localSearchResults[index];
                        return ListTile(
                          title: Text('#${hashtag.query}', style: TextStyle(color: Colors.black)),
                          trailing: hashtag.count == 0
                              ? const Text('새로운 해시태그', style: TextStyle(color: AppColors.primaryColor))
                              : Text('${hashtag.count}회', style: TextStyle(color: Colors.black)),
                          onTap: () async {
                            final tag = '${hashtag.query}';
                            if (!_hashtags.contains(tag)) {
                              setState(() {
                                _hashtags.add(tag);
                                final currentText = _contentController.text;
                                if (currentText.isNotEmpty &&
                                    !currentText.endsWith(' ')) {
                                  _contentController.text += ' ';
                                }
                                _contentController.text += '#$tag ';
                              });
                            }
                            localHashtagController.clear();
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _extractHashtagsFromContent() {
    String text = _contentController.text;
    RegExp hashtagRegExp = RegExp(r'#[\w가-힣]+');

    Iterable<Match> matches = hashtagRegExp.allMatches(text);

    setState(() {
      _hashtags.clear();
      for (Match match in matches) {
        // #을 제외한 텍스트만 저장
        String hashtag = match.group(0)!.substring(1);
        if (!_hashtags.contains(hashtag)) {
          _hashtags.add(hashtag);
        }
      }
    });
  }

  // 2. 더 자세한 정보를 포함한 방식
  void printDetailedHashtags() {
    print('==== 해시태그 목록 ====');
    print('총 개수: ${_hashtags.length}');
    for (int i = 0; i < _hashtags.length; i++) {
      print('${i + 1}번째 해시태그: ${_hashtags[i]}');
    }
    print('====================');
  }
}