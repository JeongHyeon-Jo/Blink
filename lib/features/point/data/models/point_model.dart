import 'package:blink/features/point/data/models/fruit_model.dart';

class PointModel {
  // 연결된 Tree의 ID
  final String treeId;

   // 사용자 보유 포인트
  final int points;

   // 생성된 Fruit 리스트
  final List<FruitModel> fruits;

  PointModel({
    required this.treeId,
    required this.points,
    required this.fruits,
  });

  Map<String, dynamic> toMap() {
    return {
      'treeId': treeId,
      'points': points,
      'fruits': fruits.map((f) => f.toMap()).toList(),
    };
  }

  factory PointModel.fromMap(Map<String, dynamic> map) {
    return PointModel(
      treeId: map['treeId'] as String,
      points: map['points'] as int,
      fruits: List<FruitModel>.from(
        map['fruits']?.map((x) => FruitModel.fromMap(x)),
      ),
    );
  }
}
