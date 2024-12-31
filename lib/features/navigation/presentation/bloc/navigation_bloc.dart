import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(const NavigationState(selectedIndex: 0)) {
    on<NavigationIndexChanged>(_onIndexChanged);
  }

  void _onIndexChanged(
    NavigationIndexChanged event,
    Emitter<NavigationState> emit,
  ) {
    emit(NavigationState(selectedIndex: event.index));
  }
}
