import 'dart:math';
import 'package:blink/features/point/data/datasources/remote/point_remote_datasource.dart';
import 'package:blink/features/point/data/models/fruit_model.dart';
import 'package:blink/features/point/data/models/tree_model.dart';
import 'package:blink/features/point/domain/repositories/point_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PointRepositoryImpl implements PointRepository {
  final PointRemoteDataSource remoteDataSource;
  final FirebaseFirestore firestore;

  PointRepositoryImpl({
    required this.remoteDataSource,
    required this.firestore,
  });

  @override
  Future<int> getUserPoints(String userId) async {
    print("Firebase에서 포인트 데이터 가져오기 시작: $userId");
    try {
      final snapshot = await firestore.collection('users').doc(userId).get();
      final data = snapshot.data();
      print("Firebase 데이터: $data");
      return data?['point'] ?? 0;
    } catch (e) {
      print("Firebase 에러: $e");
      throw Exception("포인트 로드 실패: $e");
    }
  }


  @override
  Future<void> addPoints(String userId, int points) => remoteDataSource.addPoints(userId, points);

  @override
  Future<void> updateUserPoints(String userId, int points) async {
    await firestore.collection('users').doc(userId).update({
      'point': FieldValue.increment(points),
    });
  }

  bool isPositionValid(double x, double y, List<FruitModel> existingFruits, double minDistance) {
    for (var fruit in existingFruits) {
      double dx = x - fruit.x;
      double dy = y - fruit.y;
      double distance = sqrt(dx * dx + dy * dy); // sqrt 함수 호출
      if (distance < minDistance) {
        return false; // 거리가 너무 가까우면 위치가 유효하지 않음
      }
    }
    return true; // 모든 기존 열매와 충분히 멀리 떨어져 있으면 유효
  }


  @override
  Future<void> waterTree(String userId, int waterAmount) async {
    try {
      final treeDoc = firestore.collection('trees').doc(userId);
      final treeSnapshot = await treeDoc.get();

      if (!treeSnapshot.exists) {
        throw Exception('Tree not found for userId: $userId');
      }

      final tree = TreeModel.fromMap(treeSnapshot.data()!);
      final updatedTree = tree.updateWaterAndLevel(waterAmount);

      // 물 1000이 넘으면 새로운 열매 생성
      if (updatedTree.water == 0) {
        final randomXGenerator = Random(DateTime.now().millisecondsSinceEpoch); // x용 랜덤 인스턴스
        final randomYGenerator = Random(DateTime.now().millisecondsSinceEpoch + 1000); // y용 랜덤 인스턴스
        final double xMin = 0.15;
        final double xMax = 0.85;
        final double yMin = 0.1;
        final double yMax = 0.85;
        const double minDistance = 0.1;

        // 새로운 위치 찾기
        double randomX, randomY;
        int maxAttempts = 100;
        bool validPositionFound = false;

        do {
          randomX = xMin + (xMax - xMin) * randomXGenerator.nextDouble() * 100;
          randomY = yMin + (yMax - yMin) * randomYGenerator.nextDouble() * 50;
          validPositionFound = isPositionValid(randomX, randomY, updatedTree.fruits, minDistance);
          maxAttempts--;
        } while (!validPositionFound && maxAttempts > 0);

        if (validPositionFound) {
          updatedTree.fruits.add(FruitModel(
            id: UniqueKey().toString(),
            x: randomX,
            y: randomY,
            status: "fruitForm",
          ));
        } else {
          print("유효한 위치를 찾지 못했습니다.");
        }
      }

      await treeDoc.update(updatedTree.toMap());
      await updateUserPoints(userId, -waterAmount);
    } catch (e) {
      throw Exception("Failed to water tree for userId $userId: ${e.toString()}");
    }
  }

  @override
  Future<List<Map<String, dynamic>>> generateFruit(String userId, int waterCount) =>
      remoteDataSource.generateFruit(userId, waterCount);

  @override
  Future<void> claimFruitReward(String userId, String fruitId) =>
      remoteDataSource.claimFruitReward(userId, fruitId);

  @override
  Future<TreeModel> getTree(String userId) async {
    final treeDoc = firestore.collection('trees').doc(userId);
    final snapshot = await treeDoc.get();

    if (!snapshot.exists) {
      final newTree = TreeModel(
        id: userId,
        userId: userId,
        level: 0,
        water: 0,
        fruits: [],
      );

      await treeDoc.set(newTree.toMap());
      return newTree;
    }

    return TreeModel.fromMap(snapshot.data()!);
  }

  @override
  Future<void> updateTree(String userId, TreeModel tree) async {
    await firestore.collection('trees').doc(userId).update(tree.toMap());
  }

  @override
  Future<void> incrementBasket(String userId) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'basket': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception("Failed to increment basket for userId $userId: ${e.toString()}");
    }
  }
}
