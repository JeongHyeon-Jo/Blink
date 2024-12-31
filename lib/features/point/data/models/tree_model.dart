import 'package:blink/features/point/data/models/fruit_model.dart';
import 'package:flutter/material.dart';

class TreeModel {
  // 나무의 고유 ID
  final String id;

  // 나무 소유자의 ID
  final String userId;

  // 현재 나무의 레벨
  final int level;

  // 현재 물의 양 (1000일 때마다 0으로 초기화)
  final int water;

  // 과일 리스트
  final List<FruitModel> fruits;

  TreeModel({
    required this.id,
    required this.userId,
    this.level = 0,
    this.water = 0,
    this.fruits = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'level': level,
      'water': water,
      'fruits': fruits.map((fruit) => fruit.toMap()).toList(),
    };
  }

  factory TreeModel.fromMap(Map<String, dynamic> map) {
    return TreeModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      level: map['level'] ?? 0,
      water: map['water'] ?? 0,
      fruits: List<FruitModel>.from(
        map['fruits']?.map((fruit) => FruitModel.fromMap(fruit)) ?? [],
      ),
    );
  }

  TreeModel updateWaterAndLevel(int addedWater) {
    final newWater = water + addedWater;
    final updatedFruits = List<FruitModel>.from(fruits);

    if (newWater >= 1000) {
      final randomX = (0.1 + (0.8 * (newWater % 100) / 100)).clamp(0.1, 0.9); // 랜덤 위치
      final randomY = (0.2 + (0.6 * (newWater % 50) / 100)).clamp(0.2, 0.8);

      updatedFruits.add(FruitModel(
        id: UniqueKey().toString(),
        x: randomX,
        y: randomY,
        status: "fruitForm",
      ));

      return TreeModel(
        id: id,
        userId: userId,
        level: level + 1,
        water: newWater - 1000,
        fruits: updatedFruits,
      );
    } else {
      return TreeModel(
        id: id,
        userId: userId,
        level: level,
        water: newWater,
        fruits: updatedFruits,
      );
    }
  }
}
