import 'dart:async';
import 'package:blink/core/theme/colors.dart';
import 'package:blink/core/utils/blink_sharedpreference.dart';
import 'package:blink/features/point/data/models/fruit_model.dart';
import 'package:blink/features/point/presentation/blocs/point_bloc/point_bloc.dart';
import 'package:blink/features/point/presentation/blocs/point_bloc/point_event.dart';
import 'package:blink/features/point/presentation/blocs/point_bloc/point_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:blink/features/user/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PointScreen extends StatefulWidget {
  const PointScreen({super.key});

  @override
  _PointScreenState createState() => _PointScreenState();
}

class _PointScreenState extends State<PointScreen> {
  final AuthRepository _authRepository = AuthRepository();
  Timer? _wateringTimer;
  int _currentWaterAmount = 0;
  bool _isPressing = false;

  @override
  void initState() {
    super.initState();
    final userIdFuture = BlinkSharedPreference().getCurrentUserId();
    userIdFuture.then((userId) {
      if (userId != 'not defined user') {
        context.read<PointBloc>().add(LoadPoints(userId));
      }
    }).catchError((error) {});
  }

  ////////////////////////////////////////////////////////////////////////////
  // 물주기 메서드
  void _startWatering(String userId, int waterLevel, int points) {
    if (points <= 0) {
      _showDialog("물 부족", "포인트가 없습니다!");
      return;
    }

    setState(() {
      _isPressing = true;
      _currentWaterAmount = 5;
    });

    int remainingPoints = points;

    _wateringTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      int _nextWaterAmount = _currentWaterAmount + 5;

      // 물 레벨이 최대치에 도달한 경우
      if (waterLevel >= 1000) {
        timer.cancel();
        context.read<PointBloc>().add(WaterTreeEvent(userId, 1000 - waterLevel));
        _showDialog("레벨 업!", "레벨이 상승하고 물이 초기화되었습니다.");
        return;
      }

      // 포인트 부족 상태를 미리 감지
      if (remainingPoints - _currentWaterAmount <= 0) {
        timer.cancel();
        int waterToGive = remainingPoints > 0 ? remainingPoints : 0; // 남은 포인트만큼만 추가
        context.read<PointBloc>().add(WaterTreeEvent(userId, waterToGive));
        _showDialog("물 부족", "포인트를 다 사용하셨습니다.");
        return;
      }

      // 다음 단계에서 음수 상태로 넘어갈 경우 처리
      if (remainingPoints - _nextWaterAmount <= 0) {
        timer.cancel();
        context.read<PointBloc>().add(WaterTreeEvent(userId, remainingPoints)); // 남은 포인트 모두 사용
        _showDialog("물 부족", "포인트를 다 사용하셨습니다.");
        return;
      }

      context.read<PointBloc>().add(WaterTreeEvent(userId, _currentWaterAmount));
      setState(() {
        remainingPoints -= _currentWaterAmount;
        _currentWaterAmount = _nextWaterAmount;
      });
    });
  }

  void _singleWater(String userId, int waterLevel, int points) {
    if (points <= 0) {
      _showDialog("물 부족", "포인트가 없습니다!");
      return;
    }

    if (waterLevel >= 1000) {
      context.read<PointBloc>().add(WaterTreeEvent(userId, 1000 - waterLevel));
      _showDialog("레벨 업!", "레벨이 상승하고 물이 초기화되었습니다.");
    } else if (points >= 5) {
      context.read<PointBloc>().add(WaterTreeEvent(userId, 5));
    } else {
      context.read<PointBloc>().add(WaterTreeEvent(userId, points));
      _showDialog("물 부족", "포인트를 다 사용하셨습니다.");
    }
  }

  void _stopWatering() {
    if (_wateringTimer != null) {
      _wateringTimer!.cancel();
      _wateringTimer = null;
    }
    setState(() {
      _currentWaterAmount = 0;
      _isPressing = false;
    });
  }

  // 물주기 메서드 종료
  ////////////////////////////////////////////////////////////////////////////
  
  ////////////////////////////////////////////////////////////////////////////
  // 열매 메서드
  void _onFruitTap(String userId, FruitModel fruit) async {
    try {
      final currentState = context.read<PointBloc>().state;

      if (currentState is PointsAndTreeUpdated) {
        // 열매 제거 후 상태 업데이트
        final updatedFruits = currentState.fruits.where((f) => f.id != fruit.id).toList();
        context.read<PointBloc>().add(UpdateFruitsEvent(userId, updatedFruits));

        // basket 값을 증가시키는 이벤트 추가
        await Future.delayed(const Duration(milliseconds: 100));
        context.read<PointBloc>().add(IncrementBasketEvent(userId));

        // 화면 갱신
        await Future.delayed(const Duration(milliseconds: 100));
        context.read<PointBloc>().add(LoadPoints(userId));
      } else {
        _showDialog("정보 로딩 중", "현재 데이터를 불러오는 중입니다. 잠시 후 다시 시도해주세요.");
      }
    } catch (e) {
      _showDialog("에러", "열매를 처리하는 도중 문제가 발생했습니다: $e");
    }
  }

  // 열매 메서드 종료
  ////////////////////////////////////////////////////////////////////////////

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("확인"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '포인트',
          style: TextStyle(color: AppColors.textWhite, fontSize: 20.sp),
        ),
        backgroundColor: AppColors.backgroundDarkGrey,
      ),
      backgroundColor: AppColors.backgroundBlackColor,
      body: MultiBlocListener(
        listeners: [
          BlocListener<PointBloc, PointState>(
            listener: (context, state) {
              print('Current state: $state');
              if (state is PointError) {
                _showDialog("오류", state.message);
              }
            },
          ),
        ],
        child: BlocBuilder<PointBloc, PointState>(
          builder: (context, state) {
            if (state is PointsLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: 30.h),
                    Text(
                      '로그인 정보를 불러올 수 없습니다.',
                      style: TextStyle(color: AppColors.textWhite, fontSize: 16.sp),
                    ),
                    Text(
                      '아래 버튼을 눌러주세요',
                      style: TextStyle(color: AppColors.textWhite, fontSize: 16.sp),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () async {
                        final userId = await BlinkSharedPreference().getCurrentUserId();
                        if (userId != 'not defined user') {
                          context.read<PointBloc>().add(LoadPoints(userId));
                        } else {
                          _showDialog("로그인 필요", "로그인 정보가 없습니다. 다시 로그인해주세요.");
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.textWhite,
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                      ),
                      child: Text("로그인 정보 불러오기", style: TextStyle(fontSize: 14.sp)),
                    ),
                  ],
                ),
              );
            }

            if (state is PointError) {
              return Center(
                child: Text(
                  state.message,
                  style: TextStyle(color: AppColors.textWhite, fontSize: 16.sp),
                ),
              );
            }

            if (state is PointsAndTreeUpdated) {
              final points = state.points;
              final waterLevel = state.water;

              return Stack(
                children: [
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.05,
                    left: 0,
                    right: 0,
                    child: Text(
                      '현재 보유 포인트: $points',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.13,
                    left: 0,
                    right: 0,
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/images/point/tree.png',
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        ),
                        // 열매 표시 (status가 fruitForm인 것만)
                        ...state.fruits
                          .where((fruit) => fruit.status == "fruitForm")
                          .map((fruit) => Positioned(
                                left: fruit.x * MediaQuery.of(context).size.width,
                                top: fruit.y * MediaQuery.of(context).size.height*0.5,
                                child: GestureDetector(
                                  onTap: state is PointsAndTreeUpdated
                                      ? () => _onFruitTap(state.userId, fruit)
                                      : null,
                                  child: Image.asset(
                                    'assets/images/point/fruit.png',
                                    width: 40.w,
                                    height: 40.h,
                                  ),
                                ),
                              )),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.135,
                    left: 16.w,
                    right: 16.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 35.h,
                          child: LinearProgressIndicator(
                            value: waterLevel / 1000,
                            backgroundColor: AppColors.backgroundLightGrey,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(AppColors.secondaryLightColor),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '$waterLevel / 1000',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textLightGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.068,
                    left: 32.w,
                    right: 32.w,
                    child: GestureDetector(
                      onLongPressStart: (_) =>
                          _startWatering(state.userId, waterLevel, points),
                      onLongPressEnd: (_) => _stopWatering(),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPressing
                              ? AppColors.primaryLightColor
                              : AppColors.primaryColor,
                          foregroundColor: AppColors.textWhite,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        onPressed: () => _singleWater(state.userId, waterLevel, points),
                        child: Text('물 주기', style: TextStyle(fontSize: 16.sp)),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16.w,
                    top: MediaQuery.of(context).size.height * 0.05,
                    child: FloatingActionButton(
                      backgroundColor: AppColors.secondaryColor,
                      onPressed: () {
                      },
                      child: Icon(
                        Icons.shopping_basket,
                        color: AppColors.iconWhite,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ],
              );
            }
            // 상태가 PointsAndTreeUpdated가 아닌 경우
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 4.w,
              ),
            );
          },
        ),
      ),
    );
  }
}
