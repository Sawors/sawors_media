import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sawors_media_client/pages/routing.dart';
import 'package:sawors_media_client/pages/splashcreen.dart';

import '../auth/auth.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final LoginPageViewModel viewModel = LoginPageViewModel();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (context, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 5,
              children: [
                TextField(
                  controller: viewModel.useridController,
                  decoration: const InputDecoration(labelText: 'User ID'),
                  autofocus: true,
                  onChanged: viewModel.updateUserid,
                ),
                TextField(
                  controller: viewModel.passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  onChanged: viewModel.updatePassword,
                  onEditingComplete: viewModel.allValid
                      ? () {
                          viewModel.submit(context);
                        }
                      : null,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: viewModel.allValid
                      ? () {
                          viewModel.submit(context);
                        }
                      : null,
                  child: const Text('Login'),
                ),
                const SizedBox(height: 30),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "If you have no account, you can ",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.dividerColor,
                        ),
                      ),
                      TextSpan(
                        text: "register here",
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            if (context.mounted) {
                              Navigator.of(
                                context,
                              ).popAndPushNamed(RouteName.register);
                            }
                          },
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class LoginPageViewModel extends ChangeNotifier {
  String _userid;
  String _password;

  late final TextEditingController passwordController;
  late final TextEditingController useridController;

  LoginPageViewModel({String? userid, String? password})
    : _userid = userid ?? "",
      _password = password ?? "" {
    passwordController = TextEditingController(text: password);
    useridController = TextEditingController(text: userid?.toLowerCase());
  }

  void updatePassword(String? password) {
    if (password != null) {
      _password = password;
    }
    notifyListeners();
  }

  void updateUserid(String? userid) {
    if (userid != null) {
      _userid = userid.toLowerCase();
    }
    notifyListeners();
  }

  Future<void> submit(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (_userid.isEmpty || _password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot login with empty credentials')),
      );
    }
    final success = await authProvider.login(_userid, _password);
    if (success) {
      if (!context.mounted) {
        return;
      }
      await SplashScreen.loadApp(context);
      await Navigator.pushReplacementNamed(context, RouteName.home);
    } else {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed! Please try again.')),
      );
    }
  }

  bool get allValid => _password.isNotEmpty && _userid.isNotEmpty;

  @override
  void dispose() {
    useridController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
