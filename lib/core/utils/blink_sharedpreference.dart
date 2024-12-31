import 'package:shared_preferences/shared_preferences.dart';

class BlinkSharedPreference {
  static BlinkSharedPreference? _instance;
  static SharedPreferences? _prefs;

  BlinkSharedPreference._internal();

  factory BlinkSharedPreference() =>
      _instance ??= BlinkSharedPreference._internal();

  Future<SharedPreferences> get prefs async {
    if (_prefs != null) return _prefs!;
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }


  // userInfo 저장
  Future<void> saveUserInfo(String userId, String email, String name , String nickname, String token) async {
    SharedPreferences preferences = await prefs;
    await preferences.setString('userId', userId);
    await preferences.setString('email', email);
    await preferences.setString('name', name);
    await preferences.setString('nickname', nickname);
    await preferences.setString('token', token);
  }

  // userId 저장
  Future<void> setUserId(String userId) async {
    SharedPreferences preferences = await prefs;
    await preferences.setString('userId', userId);
  }

  // 이메일 저장
  Future<void> setEmail(String email) async {
    SharedPreferences preferences = await prefs;
    await preferences.setString('email', email);
  }

  // 닉네임 저장
  Future<void> setNickname(String nickname) async {
    SharedPreferences preferences = await prefs;
    await preferences.setString('nickname', nickname);
  }

  // 전화번호 저장
  Future<void> setPhone(String phone) async {
    SharedPreferences preferences = await prefs;
    await preferences.setString('phone', phone);
  }

  // fcm token 저장
  Future<void> setToken(String token) async {
    SharedPreferences preferences = await prefs;
    preferences.setString('token', token);
  }

  // 이메일 읽기
  Future<String> getEmail() async {
    SharedPreferences preferences = await prefs;
    return preferences.getString('email') ?? "";
  }

  // 이름 읽기
  Future<String> getName() async {
    SharedPreferences preferences = await prefs;
    return preferences.getString('name') ?? "";
  }

  // 닉네임 읽기
  Future<String> getNickname() async {
    SharedPreferences preferences = await prefs;
    return preferences.getString('nickname') ?? "";
  }

  // 전화번호 읽기
  Future<String> getPhone() async {
    SharedPreferences preferences = await prefs;
    return preferences.getString('phone') ?? "";
  }

  // 토큰 읽기
  Future<String> getToken() async {
    SharedPreferences preferences = await prefs;
    return preferences.getString('token') ?? "";
  }

  // 유저 정보 삭제
  Future<void> removeUserInfo() async {
    SharedPreferences preferences = await prefs;
    await preferences.remove('email');
    await preferences.remove('nickname');
    await preferences.remove('phone');
    await preferences.remove('token');
  }

  // 전체 데이터 삭제
  Future<void> clearPreference() async {
    SharedPreferences preferences = await prefs;
    await preferences.clear();
  }

  // userId 가져오기
  Future<String> getCurrentUserId() async {
    SharedPreferences preferences = await prefs;
    return preferences.getString('userId') ?? 'not defined user';
  }

  // 로그아웃 시 userId 포함하여 모든 정보 삭제

  // 디버깅용 사용자 정보 체크 메서드
  Future<void> checkCurrentUser() async {
    print('=== User Info Check ===');
    print('User ID: ${await getCurrentUserId()}');
    print('Email: ${await getEmail()}');
    print('Name: ${await getName()}');
    print('Nickname: ${await getNickname()}');
    print('token: ${await getToken()}');
    print('=====================');
  }

  // 모든 데이터 프린트 - 로그아웃 전에 현재 데이터 확인
  Future<void> printAllData() async {
    SharedPreferences preferences = await prefs;
    print('=== 현재 내부 저장소에 있는 데이터 ===');
    print('User ID: ${preferences.getString('userId') ?? '없음'}');
    print('Email: ${preferences.getString('email') ?? '없음'}');
    print('Name: ${preferences.getString('name') ?? '없음'}');
    print('Nickname: ${preferences.getString('nickname') ?? '없음'}');
    print('Phone: ${preferences.getString('phone') ?? '없음'}');
    print('=========================');
  }
}
