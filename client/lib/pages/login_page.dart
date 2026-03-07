import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:sawors_media_client/pages/routing.dart';

import '../auth/auth.dart';
import '../auth/tokens.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // di/service_locator.dart
    return Scaffold(
      body: Center(
        child: FutureBuilder(
          future: GetIt.instance<TokenService>().getToken().then((token) {
            if (token == null) {
              return Future.value(null);
            } else {
              print("Token found, validating it...");
              return GetIt.instance<Dio>()
                  .get("/check-token")
                  .then((r) => r.data == "valid token" ? token : null);
            }
          }),
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState != ConnectionState.done) {
              return SizedBox.square(
                dimension: 100,
                child: CircularProgressIndicator(),
              );
            }

            final String? token = asyncSnapshot.data;
            print("Token (at login) : $token");
            if (token == null) {
              return TextButton(
                onPressed: () {
                  final userid = ""; // TODO
                  final password = ""; // TODO
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  authProvider.login(userid, password).then((success) {
                    if (success) {
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.pushReplacementNamed(context, RouteName.home);
                    } else {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Login failed! Please try again.'),
                        ),
                      );
                    }
                  });
                },
                child: Text("Login"),
              );
            } else {
              return TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, RouteName.home);
                },
                child: Text("Enter"),
              );
            }
          },
        ),
      ),
    );
  }
}
