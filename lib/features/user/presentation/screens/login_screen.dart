import 'package:blink/core/routes/app_router.dart';
import 'package:blink/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:blink/features/navigation/presentation/screens/main_navigation_screen.dart';
import 'package:blink/features/user/presentation/blocs/auth_bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  final int? destinationIndex;

  const LoginScreen({
    super.key,
    this.destinationIndex,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print("[LoginScreen] destinationIndex: ${widget.destinationIndex}");
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          print("[LoginScreen] 로그인 성공, 목적지: ${widget.destinationIndex}");
          if (widget.destinationIndex == 2) {
            context.go('/main');
            Future.delayed(const Duration(milliseconds: 100), () {
              if (context.mounted) {
                context.push('/upload_camera');
              }
            });
          } else if (widget.destinationIndex != null) {
            context.go('/main', extra: widget.destinationIndex);
          } else {
            context.go('/main', extra: 0);
          }
        } else if (state is LoginFailed) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('오류'),
              content: Text(state.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        return Stack(children: [
          Scaffold(
            appBar: AppBar(),
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 로고 또는 타이틀
                      Image.asset(
                        'assets/images/blink_logo.png',
                        width: 100.w,
                        height: 100.h,
                      ),
                      SizedBox(height: 40.h),

                      // 이메일 입력 필드
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: '이메일',
                          prefixIcon: Icon(Icons.email, size: 20.w),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '이메일을 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // 비밀번호 입력 필드
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: '비밀번호',
                          prefixIcon: Icon(Icons.lock, size: 20.w),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '비밀번호를 입력해주세요';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24.h),

                      // 로그인 버튼
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _login(_emailController.text,
                                _passwordController.text);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          '로그인',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      ),
                      // 회원가입 링크
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("계정이 없으신가요?"),
                          SizedBox(
                            width: 10.w,
                          ),
                          TextButton(
                            onPressed: () {
                              context.push('/signup');
                            },
                            child: Text(
                              '회원가입',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (state is AuthLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      '로그인 중...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ]);
      },
    );
  }

  void _login(String email, String password) async {
    // 로그인 시도 전에 키보드를 숨김
    FocusScope.of(context).unfocus();

    // 약간의 지연을 주어 키보드가 완전히 사라질 때까지 대기
    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    context.read<AuthBloc>().add(SignInRequested(
          email: email,
          password: password,
        ));
  }
}
