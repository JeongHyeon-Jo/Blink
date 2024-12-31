import 'dart:async';
import 'package:blink/core/utils/blink_sharedpreference.dart';
import 'package:blink/features/user/data/models/user_model.dart';
import 'package:blink/features/user/domain/repositories/auth_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final _auth = FirebaseAuth.instance;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    //회원가입 이벤트
    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final result = await authRepository.signUp(
          email: event.email,
          password: event.password,
          name: event.name,
        );

        if (result.isSuccess) {
          emit(const Authenticated("회원가입이 완료되었습니다. 이메일 인증 진행 후 로그인 해주세요."));
        } else {
          emit(AuthError("error : ${result.message.toString()}"));
        }
      } catch (e) {
        emit(AuthError("error : ${e.toString()}"));
      }
    });

    //로그인 이벤트
    on<SignInRequested>((event, emit) async {
      print("[AuthBloc] 로그인 시작");
      emit(AuthLoading());

      try {
        print("[AuthBloc] Firebase 인증 시작");
        final stopwatch = Stopwatch()..start();

        // Firebase 인증
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );

        print("[AuthBloc] Firebase 인증 완료: ${stopwatch.elapsedMilliseconds}ms");

        if (userCredential.user == null) {
          emit(const LoginFailed("로그인에 실패했습니다."));
          return;
        }

        // 로그인 성공 상태 emit
        emit(const LoginSuccess("로그인에 성공했습니다."));

        // 추가 정보 처리는 별도의 Future로 실행
        unawaited(_processAdditionalInfo(event.email, event.password));
      } on FirebaseAuthException catch (e) {
        print("[AuthBloc] Firebase 인증 실패: ${e.code}");
        emit(LoginFailed(_getErrorMessage(e.code)));
      } catch (e) {
        print("[AuthBloc] 예상치 못한 오류: $e");
        emit(LoginFailed("로그인 중 오류가 발생했습니다: ${e.toString()}"));
      }
    });
  }

  Future<void> _processAdditionalInfo(String email, String password) async {
    print("[AuthBloc] 추가 정보 처리 시작");
    final stopwatch = Stopwatch()..start();

    try {
      final result = await authRepository.signIn(
        email: email,
        password: password,
      );

      print("[AuthBloc] Repository 응답 수신: ${stopwatch.elapsedMilliseconds}ms");

      if (result.isSuccess && result.data != null) {
        await _saveUserInfo(result.data!);
      } else {
        print("[AuthBloc] Repository 응답 실패: ${result.message}");
      }
    } catch (e) {
      print("[AuthBloc] 추가 정보 처리 중 오류: $e");
    }
  }

  Future<void> _saveUserInfo(UserModel userData) async {
    print("[AuthBloc] SharedPreferences 저장 시작");
    final stopwatch = Stopwatch()..start();

    try {
      await BlinkSharedPreference().saveUserInfo(
        userData.id ?? "undefined user",
        userData.email ?? "undefined email",
        userData.name ?? "undefined name",
        userData.nickname ?? "undefined nickname",
        userData.pushToken ?? "",
      );
      print(
          "[AuthBloc] SharedPreferences 저장 완료: ${stopwatch.elapsedMilliseconds}ms");

      await BlinkSharedPreference().checkCurrentUser();
      print("[AuthBloc] 사용자 체크 완료");
    } catch (e) {
      print("[AuthBloc] 사용자 정보 저장 중 오류: $e");
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return "등록되지 않은 이메일입니다.";
      case 'wrong-password':
        return "잘못된 비밀번호입니다.";
      case 'invalid-email':
        return "유효하지 않은 이메일 형식입니다.";
      case 'user-disabled':
        return "비활성화된 계정입니다.";
      default:
        return "로그인에 실패했습니다.";
    }
  }
}
