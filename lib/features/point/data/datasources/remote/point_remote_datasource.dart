import 'package:cloud_firestore/cloud_firestore.dart';
class PointRemoteDataSource {
  final FirebaseFirestore firestore;

  PointRemoteDataSource({required this.firestore});

  Future<int> getUserPoints(String userId) async {
    final snapshot = await firestore.collection('users').doc(userId).get();

    if (!snapshot.exists) {
      return 0;
    }

    final data = snapshot.data();

    final points = data?['point'];
    if (points == null) {
      return 0;
    }

    return points;
  }

  Future<void> addPoints(String userId, int points) async {
    final userDoc = firestore.collection('users').doc(userId);
    await userDoc.update({
      'points': FieldValue.increment(points),
    });
  }

  Future<void> waterTree(String userId) async {
    final treeDoc = firestore.collection('trees').doc(userId);
    await treeDoc.update({
      'water': FieldValue.increment(1),
    });
  }

  // 트리 정보 가져오기
  Future<Map<String, dynamic>> getTree(String userId) async {
    final snapshot = await firestore.collection('trees').doc(userId).get();
    return snapshot.data() ?? {};
  }

  // 트리 정보 업데이트
  Future<void> updateTree(String userId, Map<String, dynamic> treeData) async {
    await firestore.collection('trees').doc(userId).set(treeData);
  }

  Future<List<Map<String, dynamic>>> generateFruit(String userId, int waterCount) async {
    if (waterCount >= 5) {
      // Generate random fruits
      final fruits = List<Map<String, dynamic>>.generate(3, (index) {
        final id = 'fruit_${DateTime.now().millisecondsSinceEpoch}_$index';
        return {
          'id': id,
          'position': {
            'x': (index + 1) * 50,
            'y': (index + 1) * 30,
          },
        };
      });

      // Save fruits in Firestore
      final fruitCollection = firestore.collection('trees').doc(userId).collection('fruits');
      for (final fruit in fruits) {
        final fruitId = fruit['id'];
        if (fruitId != null && fruitId is String) {
          await fruitCollection.doc(fruitId).set(fruit);
        } else {
          throw Exception("Fruit ID is null or invalid: $fruit");
        }
      }

      return fruits;
    }
    return [];
  }

  Future<void> claimFruitReward(String userId, String fruitId) async {
    final fruitDoc = firestore.collection('trees').doc(userId).collection('fruits').doc(fruitId);
    await fruitDoc.delete();
  }
}
