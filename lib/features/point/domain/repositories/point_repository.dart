import 'package:blink/features/point/domain/entities/point_entity.dart';
import 'package:blink/features/point/data/models/tree_model.dart';

abstract class PointRepository {
  Future<int> getUserPoints(String userId);

  Future<void> updateUserPoints(String userId, int points);

  Future<void> waterTree(String userId, int waterAmount);

  Future<void> addPoints(String userId, int points);

  Future<List<Map<String, dynamic>>> generateFruit(String userId, int waterCount);

  Future<void> claimFruitReward(String userId, String fruitId);

  // 트리 정보 가져오기
  Future<TreeModel> getTree(String userId);

  // 트리 정보 업데이트
  Future<void> updateTree(String userId, TreeModel tree);

  // 열매 따면 점수 올라감
  Future<void> incrementBasket(String userId);
}
