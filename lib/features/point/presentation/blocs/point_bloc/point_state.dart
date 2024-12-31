import 'package:blink/features/point/data/models/fruit_model.dart';

abstract class PointState {}

class PointsLoading extends PointState {}

class PointsLoaded extends PointState {
  final int points;

  PointsLoaded(this.points);
}

class TreeWatered extends PointState {}

class FruitClaimed extends PointState {}

class PointError extends PointState {
  final String message;

  PointError(this.message);
}

class PointsAndTreeUpdated extends PointState {
  final int points;
  final int treeLevel;
  final int water;
  final String userId;
  final List<FruitModel> fruits;

  PointsAndTreeUpdated({
    required this.points,
    required this.treeLevel,
    required this.water,
    required this.userId,
    required this.fruits,
  });
}
