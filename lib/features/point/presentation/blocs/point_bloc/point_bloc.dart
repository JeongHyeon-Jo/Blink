import 'package:blink/features/point/data/models/tree_model.dart';
import 'package:blink/features/point/domain/repositories/point_repository.dart';
import 'package:blink/features/point/presentation/blocs/point_bloc/point_event.dart';
import 'package:blink/features/point/presentation/blocs/point_bloc/point_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PointBloc extends Bloc<PointEvent, PointState> {
  final PointRepository repository;
  final _eventQueue = <PointEvent>[];

  PointBloc(this.repository) : super(PointsLoading()) {
    void _processEventQueue(Emitter<PointState> emit) async {
      print("_processEventQueue 호출, 이벤트 수: ${_eventQueue.length}");
      while (_eventQueue.isNotEmpty) {
        final nextEvent = _eventQueue.removeAt(0);
        print("다음 이벤트 처리: $nextEvent");
        add(nextEvent);
      }
    }

    // LoadPoints 이벤트 처리
    on<LoadPoints>((event, emit) async {
      print("LoadPoints 이벤트 시작: userId = ${event.userId}");
      try {
        final points = await repository.getUserPoints(event.userId);
        print("포인트 로드 완료: $points");
        final tree = await repository.getTree(event.userId);
        print("트리 로드 완료: $tree");

        emit(PointsAndTreeUpdated(
          points: points,
          treeLevel: tree.level,
          water: tree.water,
          userId: event.userId,
          fruits: tree.fruits,
        ));
        _processEventQueue(emit);
      } catch (e) {
        print("LoadPoints 에러 발생: $e");
        emit(PointError("포인트 불러오기 실패!: $e"));
        _processEventQueue(emit);
      }
    });

    // WaterTreeEvent 처리
    on<WaterTreeEvent>((event, emit) async {
      final currentState = state;
      if (currentState is PointsAndTreeUpdated) {
        try {
          await repository.waterTree(event.userId, event.waterAmount);

          final updatedPoints = await repository.getUserPoints(event.userId);
          final updatedTree = await repository.getTree(event.userId);

          emit(PointsAndTreeUpdated(
            points: updatedPoints,
            treeLevel: updatedTree.level,
            water: updatedTree.water,
            userId: event.userId,
            fruits: updatedTree.fruits,
          ));
        } catch (e) {
          emit(PointError("물주기 실패!: ${e.toString()}"));
          // 에러 후 이전 상태로 복구
          emit(currentState);
        }
      }
    });

    // ClaimFruit 이벤트 처리
    on<ClaimFruit>((event, emit) async {
      emit(PointsLoading());
      try {
        await repository.claimFruitReward(
          event.userId,
          event.fruitId,
        );
        emit(FruitClaimed());
        add(LoadPoints(event.userId));
      } catch (e) {
        emit(PointError("Failed to claim fruit: $e"));
      }
    });

    on<UpdateFruitsEvent>((event, emit) async {
      if (state is PointsLoading) {
        return;
      }

      try {
        final tree = await repository.getTree(event.userId);

        final updatedTree = TreeModel(
          id: tree.id,
          userId: tree.userId,
          level: tree.level,
          water: tree.water,
          fruits: event.fruits,
        );

        await repository.updateTree(event.userId, updatedTree);

        if (state is PointsAndTreeUpdated) {
          final currentState = state as PointsAndTreeUpdated;
          emit(PointsAndTreeUpdated(
            points: currentState.points,
            treeLevel: updatedTree.level,
            water: updatedTree.water,
            userId: updatedTree.userId,
            fruits: updatedTree.fruits,
          ));
        }
      } catch (e) {
        emit(PointError("열매 업데이트 실패: ${e.toString()}"));
      }
    });

    on<IncrementBasketEvent>((event, emit) async {
      if (state is PointsLoading) {
        return;
      }

      try {
        await repository.incrementBasket(event.userId);

        if (state is PointsAndTreeUpdated) {
          final currentState = state as PointsAndTreeUpdated;
          emit(PointsAndTreeUpdated(
            points: currentState.points,
            treeLevel: currentState.treeLevel,
            water: currentState.water,
            userId: currentState.userId,
            fruits: currentState.fruits,
          ));
        }
      } catch (e) {
        emit(PointError("Basket 증가 실패: ${e.toString()}"));
      }
    });
  }
}
