part of 'navigation_bloc.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

class NavigationIndexChanged extends NavigationEvent {
  final int index;

  const NavigationIndexChanged(this.index);

  @override
  List<Object> get props => [index];
}
