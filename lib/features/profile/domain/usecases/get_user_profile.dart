import 'package:blink/features/user/domain/repositories/auth_repository.dart';
import 'package:blink/features/user/domain/entities/user_entity.dart';

class GetUserProfile {
  final AuthRepository repository;

  GetUserProfile(this.repository);

  Future<UserEntity> call(String userId) async {
    final userModel = await repository.getUserDataWithUserId(userId);

    if (userModel == null) {
      throw Exception("UserModel이 null입니다. 유효한 사용자 ID를 전달했는지 확인하세요.");
    }

    return userModel.toEntity();
  }
}
