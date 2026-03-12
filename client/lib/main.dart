import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:sawors_media_client/meta/meta_manager.dart';
import 'package:sawors_media_client/pages/login_page.dart';
import 'package:sawors_media_client/pages/mainpage/app_display.dart';
import 'package:sawors_media_client/pages/register_page.dart';
import 'package:sawors_media_client/pages/routing.dart';
import 'package:sawors_media_client/pages/splashcreen.dart';
import 'package:sawors_media_client/theming/theming.dart';

import 'auth/auth.dart';
import 'auth/tokens.dart';

final GetIt locator = GetIt.instance;
final String userid = "sawors";

void setupLocator(String userid) {
  locator.registerLazySingleton<Dio>(() {
    // TODO : server selection here
    final String baseUrl;
    if (Platform.isAndroid || Platform.isIOS) {
      baseUrl = "http://10.0.2.2:4141/api/";
    } else {
      baseUrl = "http://localhost:4141/api/";
    }
    final dio = Dio(BaseOptions(baseUrl: baseUrl));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await locator<TokenService>().getToken(userid);
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
  locator.registerLazySingleton<ClientMetaManager>(
    () => ClientMetaManager(dio: locator<Dio>()),
  );
  locator.registerLazySingleton<FlutterSecureStorage>(
    () => FlutterSecureStorage(),
  );
}

void main() {
  setupLocator(userid);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.brightness = Brightness.dark});
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final Dio dio = locator<Dio>();
    final AuthProvider authProvider = AuthProvider(AuthService(dio), userid);
    return ChangeNotifierProvider(
      create: (context) => authProvider,
      child: MaterialApp(
        title: 'Sawors Media',
        theme: ThemeProvider.forBrightness(brightness),
        initialRoute: RouteName.startup,
        routes: {
          RouteName.home: (context) => const AppDisplay(),
          RouteName.login: (context) => LoginPage(),
          RouteName.register: (context) =>
              RegisterPage(registerViewModel: RegisterPageViewModel()),
          RouteName.startup: (context) => SplashScreen(),
        }, //const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}
