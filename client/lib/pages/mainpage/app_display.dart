import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:sawors_media_client/auth/auth.dart';
import 'package:sawors_media_client/pages/mainpage/subpages/home/home_display.dart';
import 'package:sawors_media_client/user/user_icon.dart';

class AppDisplay extends StatelessWidget {
  const AppDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final double titleBarHeight = 50;
    final AppDisplayViewModel viewModel = AppDisplayViewModel();
    final size = MediaQuery.sizeOf(context);
    final bool doMobileView = size.width / size.height < 0.7;
    final String brandingStyle =
        "${doMobileView ? "icon" : "logo"}-${Theme.of(context).brightness.name}";
    return Scaffold(
      body: Stack(
        alignment: AlignmentGeometry.topCenter,
        children: [
          ListenableBuilder(
            listenable: viewModel,
            builder: (context, child) {
              return SingleChildScrollView(
                child: switch (viewModel.selectedSubPage) {
                  "home" => HomeDisplay(),
                  _ => throw UnimplementedError(),
                },
              );
            },
          ),
          SizedBox(
            width: double.infinity,
            height: titleBarHeight + 20,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withAlpha((255 * 0.66).toInt()),
                        Colors.black.withAlpha((255 * 0.2).toInt()),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 10),
            child: SizedBox(
              height: titleBarHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FutureBuilder(
                        future: GetIt.instance<Dio>().get(
                          "/branding",
                          data: jsonEncode([brandingStyle]),
                        ),
                        builder: (context, data) {
                          final response = data.data;
                          try {
                            final content = jsonDecode(response?.data);
                            final base64Logo = base64Decode(
                              content[brandingStyle],
                            );
                            return Image.memory(base64Logo);
                          } catch (_) {}
                          return Text("Sawors Media");
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: ListenableBuilder(
                        listenable: viewModel,

                        builder: (context, child) {
                          return SegmentedButton(
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: "home",
                                label: doMobileView
                                    ? Icon(Icons.home)
                                    : Text("Home"),
                              ),
                              ButtonSegment(
                                value: "favorites",
                                label: doMobileView
                                    ? Icon(Icons.star)
                                    : Text("Favorites"),
                              ),
                            ],
                            onSelectionChanged: (s) {
                              viewModel.goToPage(s.first);
                            },
                            selected: {viewModel.selectedSubPage},
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox.square(
                        dimension: titleBarHeight,
                        child: UserIcon(
                          user: Provider.of<AuthProvider>(context).getUser(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppDisplayViewModel extends ChangeNotifier {
  String _selectedSubPage = "home";

  AppDisplayViewModel({String initialPage = "home"}) {
    _selectedSubPage = initialPage;
  }

  void goToPage(String target) {
    _selectedSubPage = target;
    notifyListeners();
  }

  String get selectedSubPage => _selectedSubPage;
}
