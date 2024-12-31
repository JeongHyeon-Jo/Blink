import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:blink/features/user/data/models/user_model.dart';
import 'package:blink/core/theme/colors.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _introductionController = TextEditingController();
  List<TextEditingController> _dynamicLinkControllers = [];
  String? _profileImagePath;
  UserModel? _user;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _user = UserModel.fromJson(doc.data()!);
            _nameController.text = _user?.name ?? '';
            _nicknameController.text = _user?.nickname ?? '';
            _introductionController.text = _user?.introduction ?? '';
            _dynamicLinkControllers = (_user?.linkList ?? []).map((link) {
              final controller = TextEditingController();
              controller.text = link;
              return controller;
            }).toList();
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint("데이터 로드 실패: $e");
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _removeEmptyLinks() {
    setState(() {
      _dynamicLinkControllers.removeWhere((controller) => controller.text.trim().isEmpty);
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImagePath = pickedFile.path;
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      debugPrint("이미지 업로드 실패: $e");
      return null;
    }
  }

  Future<void> _saveProfile() async {
    _removeEmptyLinks();
    if (_user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final nicknameQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('nickname', isEqualTo: _nicknameController.text)
          .get();
      if (nicknameQuery.docs.isNotEmpty &&
          _nicknameController.text != _user!.nickname) {
        _showErrorDialog("닉네임 설정 실패", "이미 사용 중인 닉네임입니다.");
        setState(() {
          _isSaving = false;
        });
        return;
      }

      String? updatedProfileImageUrl = _user!.profileImageUrl;

      if (_profileImagePath != null) {
        updatedProfileImageUrl = await _uploadImage(File(_profileImagePath!));
      }

      final updatedUser = _user!.copyWith(
        name: _nameController.text,
        nickname: _nicknameController.text,
        introduction: _introductionController.text,
        linkList: _dynamicLinkControllers
            .map((controller) => controller.text)
            .toList(),
        profileImageUrl: updatedProfileImageUrl,
        updatedAt: DateTime.now(),
      );

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid);

      await docRef.set(updatedUser.toMap());

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("프로필 업데이트 실패: $e");
      _showErrorDialog("업데이트 실패", "프로필 업데이트 중 오류가 발생했습니다.");
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(color: AppColors.errorRed)),
        content: Text(content, style: TextStyle(color: AppColors.textWhite)),
        backgroundColor: AppColors.backgroundDarkGrey,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("확인", style: TextStyle(color: AppColors.primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundBlackColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryColor),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundBlackColor,
        body: Center(
          child: Text(
            "유저 정보를 불러올 수 없습니다.",
            style: TextStyle(color: AppColors.textWhite),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.backgroundBlackColor,
        title: const Text("프로필 편집", style: TextStyle(color: AppColors.textWhite)),
        actions: [
          _isSaving
              ? Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: Center(
                    child: SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.w,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save, color: AppColors.textWhite),
                  onPressed: _saveProfile,
                ),
        ],
      ),
      body: Container(
        color: AppColors.backgroundBlackColor,
        padding: EdgeInsets.all(16.w),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 75.r,
                    backgroundColor: AppColors.backgroundDarkGrey,
                    child: ClipOval(
                      child: _profileImagePath != null
                          ? Image.file(
                              File(_profileImagePath!),
                              fit: BoxFit.cover,
                              width: 150.r,
                              height: 150.r,
                            )
                          : (_user!.profileImageUrl != null &&
                                  _user!.profileImageUrl!.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: _user!.profileImageUrl!,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator(color: AppColors.primaryColor),
                                  errorWidget: (context, url, error) =>
                                      Image.asset("assets/images/default_profile.png"),
                                  fit: BoxFit.cover,
                                  width: 150.r,
                                  height: 150.r,
                                )
                              : Image.asset(
                                  "assets/images/default_profile.png",
                                  fit: BoxFit.cover,
                                  width: 150.r,
                                  height: 150.r,
                                ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "이름",
                  labelStyle: TextStyle(color: AppColors.textGrey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.textGrey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryColor),
                  ),
                ),
                style: TextStyle(color: AppColors.textWhite),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: "@username",
                  labelStyle: TextStyle(color: AppColors.textGrey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.textGrey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryColor),
                  ),
                ),
                style: TextStyle(color: AppColors.textWhite),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: _introductionController,
                decoration: InputDecoration(
                  labelText: "자기소개",
                  labelStyle: TextStyle(color: AppColors.textGrey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.textGrey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primaryColor),
                  ),
                ),
                style: TextStyle(color: AppColors.textWhite),
              ),
              SizedBox(height: 20.h),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("관련 링크", style: TextStyle(color: AppColors.textWhite)),
                      if (_dynamicLinkControllers.length < 5)
                        IconButton(
                          icon: Icon(Icons.add_circle_outline, color: AppColors.successGreen),
                          onPressed: () {
                            setState(() {
                              _dynamicLinkControllers.add(TextEditingController());
                            });
                          },
                        ),
                    ],
                  ),
                  Column(
                    children: _dynamicLinkControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                hintText: "링크 입력",
                                labelText: "링크 ${index + 1}",
                                labelStyle: TextStyle(color: AppColors.textGrey),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.textGrey),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.primaryColor),
                                ),
                              ),
                              style: TextStyle(color: AppColors.textWhite),
                              onChanged: (_) => _removeEmptyLinks(),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: AppColors.errorRed),
                            onPressed: () {
                              setState(() {
                                _dynamicLinkControllers.removeAt(index);
                              });
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
