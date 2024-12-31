import 'package:blink/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/repositories/comment_repository.dart';
import '../../data/models/comment_model.dart';
import 'package:blink/core/utils/blink_sharedpreference.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommentBottomSheet extends StatefulWidget {
  final String videoId;
  final Function()? onCommentUpdated;

  const CommentBottomSheet({
    super.key,
    required this.videoId,
    this.onCommentUpdated,
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final _commentController = TextEditingController();
  final _commentRepository = CommentRepository();
  final _sharedPreference = BlinkSharedPreference();
  List<CommentModel> comments = [];
  String? _editingCommentId;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    final loadedComments = await _commentRepository.getComments(widget.videoId);
    if (mounted) {
      setState(() {
        comments = loadedComments;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _startEditing(CommentModel comment) {
    setState(() {
      _editingCommentId = comment.id;
      _commentController.text = comment.content;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingCommentId = null;
      _commentController.clear();
    });
  }

  Future<void> _handleSubmit() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    try {
      if (_editingCommentId != null) {
        await _commentRepository.updateComment(_editingCommentId!, content);
        _cancelEditing();
      } else {
        final currentUser = await _sharedPreference.getCurrentUserId();
        await _commentRepository.addComment(
          widget.videoId,
          currentUser,
          content,
        );
      }
      _commentController.clear();
      await _loadComments();
      widget.onCommentUpdated?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 처리 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmDialog(CommentModel comment) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          '댓글 삭제',
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
        ),
        content: Text(
          '이 댓글을 삭제하시겠습니까?',
          style: TextStyle(color: Colors.white, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '취소',
              style: TextStyle(color: Colors.white54, fontSize: 14.sp),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteComment(comment);
            },
            child: Text(
              '삭제',
              style: TextStyle(color: AppColors.primaryColor, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(CommentModel comment) async {
    try {
      await _commentRepository.deleteComment(widget.videoId, comment.id);
      await _loadComments();
      widget.onCommentUpdated?.call();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('댓글 삭제 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.only(
        top: 16.h,
        left: 16.w,
        right: 16.w,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '댓글',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Divider(height: 16.h, color: Colors.white24),
          Expanded(
            child: ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) =>
                  _buildCommentItem(comments[index]),
            ),
          ),
          Divider(height: 16.h, color: Colors.white24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText:
                        _editingCommentId != null ? '댓글 수정...' : '댓글 작성...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.r),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.r),
                      borderSide: const BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.r),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                  ),
                ),
              ),
              if (_editingCommentId != null)
                IconButton(
                  onPressed: _cancelEditing,
                  icon: const Icon(Icons.close),
                  color: Colors.white54,
                ),
              IconButton(
                onPressed: _handleSubmit,
                icon:
                    Icon(_editingCommentId != null ? Icons.check : Icons.send),
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipOval(
            child: comment.writerProfileUrl != null &&
                    comment.writerProfileUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: comment.writerProfileUrl!,
                    placeholder: (context, url) => CircularProgressIndicator(
                      strokeWidth: 2.w,
                      color: AppColors.primaryColor,
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      "assets/images/default_profile.png",
                      width: 36.r,
                      height: 36.r,
                      fit: BoxFit.cover,
                    ),
                    width: 36.r,
                    height: 36.r,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    "assets/images/default_profile.png",
                    width: 36.r,
                    height: 36.r,
                    fit: BoxFit.cover,
                  ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comment.writerNickname,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  comment.content,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<String>(
            future: _sharedPreference.getCurrentUserId(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == comment.writerId) {
                return PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.white54,
                    size: 18.sp,
                  ),
                  color: Colors.black87,
                  position: PopupMenuPosition.under,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            color: Colors.white54,
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '수정',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            color: Colors.white54,
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '삭제',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _startEditing(comment);
                        break;
                      case 'delete':
                        _showDeleteConfirmDialog(comment);
                        break;
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
