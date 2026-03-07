import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:sawors_media_client/pages/routing.dart';
import 'package:sawors_media_common/user.dart';

import '../auth/auth.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key, required this.registerViewModel});
  final RegisterPageViewModel registerViewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(50.0),
        child: ListenableBuilder(
          listenable: registerViewModel,
          builder: (context, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 5,
              children: [
                TextField(
                  controller: registerViewModel.regKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Registration Key',
                  ),
                  onChanged: registerViewModel.checkRegKey,
                ),
                Row(
                  spacing: 5,
                  children: [
                    registerViewModel.regKeyError == null
                        ? Icon(
                            Icons.check,
                            color: theme.colorScheme.primary,
                            size: 19,
                          )
                        : Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                            size: 19,
                          ),

                    Text(
                      registerViewModel.regKeyError ?? "",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: registerViewModel.usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  onChanged: registerViewModel.checkUsername,
                ),
                Row(
                  spacing: 5,
                  children: registerViewModel.usernameController.text.isNotEmpty
                      ? [
                          registerViewModel._usernameError == null
                              ? Icon(
                                  Icons.check,
                                  color: theme.colorScheme.primary,
                                  size: 19,
                                )
                              : Icon(
                                  Icons.error_outline,
                                  color: theme.colorScheme.error,
                                  size: 19,
                                ),

                          registerViewModel.usernameError != null
                              ? Text(
                                  registerViewModel.usernameError!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                )
                              : Text(
                                  "@${User.userIdFromName(registerViewModel.usernameController.text.trim())}",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.disabledColor,
                                  ),
                                ),
                        ]
                      : [],
                ),
                TextField(
                  controller: registerViewModel.passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  onChanged: registerViewModel.checkPassword,
                ),
                Row(
                  spacing: 5,
                  children: registerViewModel.passwordController.text.isNotEmpty
                      ? [
                          registerViewModel.passwordError == null
                              ? Icon(
                                  Icons.check,
                                  color: theme.colorScheme.primary,
                                  size: 19,
                                )
                              : Icon(
                                  Icons.error_outline,
                                  color: theme.colorScheme.error,
                                  size: 19,
                                ),
                          Text(
                            registerViewModel.passwordError ?? "",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ]
                      : [],
                ),
                TextField(
                  controller: registerViewModel.confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                  ),
                  onChanged: registerViewModel.checkConfirmPassword,
                ),
                Row(
                  spacing: 5,
                  children:
                      registerViewModel
                          .confirmPasswordController
                          .text
                          .isNotEmpty
                      ? [
                          registerViewModel.confirmPasswordError == null
                              ? Icon(
                                  Icons.check,
                                  color: theme.colorScheme.primary,
                                  size: 19,
                                )
                              : Icon(
                                  Icons.error_outline,
                                  color: theme.colorScheme.error,
                                  size: 19,
                                ),
                          Text(
                            registerViewModel.confirmPasswordError ?? "",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ]
                      : [],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: registerViewModel.allValid
                      ? () {
                          registerViewModel.submit(context);
                        }
                      : null,
                  child: const Text('Register'),
                ),
                const SizedBox(height: 30),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "If you have an account, ",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.dividerColor,
                        ),
                      ),
                      TextSpan(
                        text: "login",
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            if (context.mounted) {
                              Navigator.of(
                                context,
                              ).popAndPushNamed(RouteName.login);
                            }
                          },
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: " instead",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.dividerColor,
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

class RegisterPageViewModel extends ChangeNotifier {
  List<int> _profilePictureData;

  late final TextEditingController regKeyController;
  late final TextEditingController usernameController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;

  String? _usernameError;
  String? _regKeyError;
  String? _passwordError;
  String? _confirmPasswordError;

  String _userId = "";
  String _userName = "";
  String _password = "";
  String _regKey = "";

  RegisterPageViewModel({
    String? registerKey,
    String? userName,
    String? password,
    List<int>? profilePictureData,
  }) : _profilePictureData = profilePictureData ?? [] {
    regKeyController = TextEditingController(
      text: registerKey ?? "bidibop", //Uri.base.queryParameters["key"]
    );
    usernameController = TextEditingController(text: userName);
    passwordController = TextEditingController(text: password);
    confirmPasswordController = TextEditingController(text: password);
    checkPassword(passwordController.text);
    checkConfirmPassword(confirmPasswordController.text);
    checkUsername(usernameController.text);
    checkRegKey(regKeyController.text);
  }

  void checkUsername(String? username) {
    if (username != null && username.isNotEmpty) {
      final uid = User.userIdFromName(username);
      if (uid == null) {
        _usernameError = "Invalid username";
        notifyListeners();
        return;
      }
      GetIt.instance<Dio>()
          .get("username-available", data: uid)
          .then(
            (r) {
              print(r.data);
              if (r.data.toString() == "true") {
                _usernameError = null;
                _userId = uid;
                _userName = username;
              } else if (r.data.toString() == "false") {
                _usernameError = "Username already exists";
              } else if (r.statusCode != null && r.statusCode! >= 400) {
                _usernameError = "Server error !";
              }
              notifyListeners();
            },
            onError: (r) {
              _usernameError = "Invalid username";
              notifyListeners();
            },
          );
    } else {
      notifyListeners();
    }
  }

  void checkPassword(String? password) {
    checkConfirmPassword(confirmPasswordController.text);
    if (password != null && password.isNotEmpty) {
      List<String> messages = [];
      if (password.length < 6) {
        messages.add("Password must be at least 6 characters long");
      }
      if (messages.isNotEmpty) {
        _passwordError = messages.join("\n");
      } else {
        _passwordError = null;
        _password = password;
      }
      notifyListeners();
      return;
    }
    if (password?.trim() != confirmPasswordController.text.trim()) {
      _confirmPasswordError = "Passwords do not match";
    } else {
      _confirmPasswordError = null;
    }
    notifyListeners();
  }

  void checkConfirmPassword(String? password) {
    if (password != null &&
        password.isNotEmpty &&
        password.trim() != passwordController.text.trim()) {
      _confirmPasswordError = "Passwords do not match";
    } else {
      _confirmPasswordError = null;
    }
    notifyListeners();
  }

  void checkRegKey(String? regKey) {
    print(regKey);
    if (regKey != null && regKey.isNotEmpty) {
      GetIt.instance<Dio>()
          .get("validate-reg-key", data: regKey)
          .then(
            (r) {
              print(r.data);
              if (r.data.toString() == "true") {
                _regKeyError = null;
                _regKey = regKey;
              } else if (r.data.toString() == "false") {
                _regKeyError = "Key is not valid";
              }
              notifyListeners();
            },
            onError: (r) {
              _regKeyError = "Key is not valid";
              notifyListeners();
            },
          );
    } else {
      _regKeyError = "Key is empty";
      notifyListeners();
    }
  }

  Future<bool> submit(BuildContext context) async {
    final user = User(
      userid: _userId,
      profilePicture: null,
      displayName: _userName,
    );
    final payload = {
      "userdata": user.toJson(),
      "register-key": _regKey,
      "password": _password,
    };
    try {
      final response = await GetIt.instance<Dio>().get(
        "register",
        data: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        if (!context.mounted) {
          return false;
        }
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.login(_userId, _password).then((success) {
          if (success) {
            if (!context.mounted) {
              return;
            }
            Navigator.pushReplacementNamed(context, RouteName.home);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Successfully logged in as $_userName')),
            );
            print("Login success");
            return;
          } else {
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Login failed! Please try again.')),
            );
          }
        });
      }
    } catch (e) {
      print("error ${e}");
    }
    return false;
  }

  @override
  void dispose() {
    regKeyController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String? get confirmPasswordError => _confirmPasswordError;

  String? get passwordError => _passwordError;

  String? get regKeyError => _regKeyError;

  String? get usernameError => _usernameError;

  bool get allValid =>
      _confirmPasswordError == null &&
      confirmPasswordController.text.isNotEmpty &&
      _passwordError == null &&
      passwordController.text.isNotEmpty &&
      _regKeyError == null &&
      regKeyController.text.isNotEmpty &&
      _usernameError == null &&
      usernameController.text.isNotEmpty;
}
