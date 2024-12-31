class FruitModel {
  final String id; // 고유 ID
  final double x; // X 좌표
  final double y; // Y 좌표
  final String status; // "fruitForm" or "picked"

  FruitModel({
    required this.id,
    required this.x,
    required this.y,
    this.status = "fruitForm",
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'status': status,
    };
  }

  factory FruitModel.fromMap(Map<String, dynamic> map) {
    return FruitModel(
      id: map['id'] as String,
      x: map['x'] as double,
      y: map['y'] as double,
      status: map['status'] as String? ?? "fruitForm",
    );
  }
}
