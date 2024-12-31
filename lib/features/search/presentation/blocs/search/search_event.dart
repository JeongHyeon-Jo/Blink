import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PerformSearchEvent extends SearchEvent {
  final String query;

  PerformSearchEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class SaveSearchEvent extends SearchEvent {
  final String query;

  SaveSearchEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class DeleteSearchEvent extends SearchEvent {
  final String query;

  DeleteSearchEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadRecentSearchEvent extends SearchEvent {}
