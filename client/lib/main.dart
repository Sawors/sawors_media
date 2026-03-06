import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:sawors_media_client/pages/homepage.dart';
import 'package:sawors_media_client/pages/login_page.dart';
import 'package:sawors_media_client/pages/routing.dart';
import 'package:sawors_media_client/theming/theming.dart';

import 'auth/auth.dart';
import 'auth/tokens.dart';

final GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<Dio>(() {
    final dio = Dio(BaseOptions(baseUrl: "http://localhost:4141/api/"));
    // api_URL can be your servers URL e.g: 'http://localhost:7087/api/'
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add JWT token to request headers
          final token = await locator<TokenService>().getToken();
          if (token != null) {
            options.headers['Authorization'] = token;
          }
          return handler.next(options);
        },
      ),
    );
    return dio;
  });

  locator.registerLazySingleton<AuthService>(() => AuthService(locator<Dio>()));
  locator.registerLazySingleton<TokenService>(() => TokenService());
  locator.registerLazySingleton<FlutterSecureStorage>(
    () => FlutterSecureStorage(),
  );
}

void main() {
  setupLocator();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.brightness = Brightness.dark});
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final Dio dio = locator<Dio>();
    final AuthProvider authProvider = AuthProvider(AuthService(dio));
    return ChangeNotifierProvider(
      create: (context) => authProvider,
      child: MaterialApp(
        title: 'Sawors Media',
        theme: ThemeProvider.forBrightness(brightness),
        initialRoute: RouteName.login,
        routes: {
          RouteName.home: (context) => Homepage(),
          RouteName.login: (context) => const LoginPage(),
        }, //const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}
