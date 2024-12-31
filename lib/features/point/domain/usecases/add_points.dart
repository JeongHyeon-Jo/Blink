import 'package:blink/features/point/domain/repositories/point_repository.dart';

class AddPoints {
  final PointRepository repository;

  AddPoints({required this.repository});

  Future<void> call(String userId, int points) async {
    await repository.addPoints(userId, points);
  }
}
