import 'package:blink/features/point/domain/usecases/add_points.dart';
import 'package:blink/features/upload/domain/repositories/upload_repository.dart';
import 'package:blink/features/upload/presentation/blocs/upload/upload_video_bloc.dart';
import 'package:blink/features/user/domain/repositories/auth_repository.dart';
import 'package:blink/features/user/presentation/blocs/auth_bloc/auth_bloc.dart';
import 'package:blink/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:blink/features/video/data/repositories/video_repository_impl.dart';
import 'package:blink/features/video/domain/repositories/video_repository.dart';
import 'package:blink/features/video/presentation/blocs/video/video_bloc.dart';
import 'package:blink/features/search/data/datasources/remote/search_remote_datasource.dart';
import 'package:blink/features/search/data/repositories/search_repository_impl.dart';
import 'package:blink/features/search/domain/repositories/search_repository.dart';
import 'package:blink/features/search/domain/usecases/delete_search_query.dart';
import 'package:blink/features/search/domain/usecases/save_search_query.dart';
import 'package:blink/features/search/domain/usecases/search_query.dart';
import 'package:blink/features/search/presentation/blocs/search/search_bloc.dart';
import 'package:blink/features/point/data/datasources/remote/point_remote_datasource.dart';
import 'package:blink/features/point/data/repositories/point_repository_impl.dart';
import 'package:blink/features/point/domain/repositories/point_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Firebase
  sl.registerLazySingleton(() => FirebaseFirestore.instance);

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Data Sources
  sl.registerLazySingleton<SearchRemoteDataSource>(
      () => SearchRemoteDataSource(firestore: sl()));
  sl.registerLazySingleton<PointRemoteDataSource>(
      () => PointRemoteDataSource(firestore: sl()));

  // Repository
  sl.registerLazySingleton<SearchRepository>(
      () => SearchRepositoryImpl(remoteDataSource: sl()));
  sl.registerLazySingleton<PointRepository>(() => PointRepositoryImpl(
        remoteDataSource: sl(),
        firestore: sl(),
      ));
  sl.registerLazySingleton<VideoRepository>(() => VideoRepositoryImpl());

  // Use Cases
  sl.registerLazySingleton(() => SearchQuery(sl()));
  sl.registerLazySingleton(() => SaveSearchQuery(sl()));
  sl.registerLazySingleton(() => DeleteSearchQuery(sl()));
  sl.registerLazySingleton(() => AddPoints(repository: sl()));

  // Blocs
  sl.registerFactory(() => VideoBloc(videoRepository: sl()));
  sl.registerFactory(() => NavigationBloc());
  sl.registerFactory(() => UploadVideoBloc(uploadRepository: UploadRepository()));
  sl.registerFactory(() => AuthBloc(authRepository: AuthRepository()));
  sl.registerFactory(() => SearchBloc(
        searchQuery: sl<SearchQuery>(),
        saveSearchQuery: sl<SaveSearchQuery>(),
        deleteSearchQuery: sl<DeleteSearchQuery>(),
      ));
}
