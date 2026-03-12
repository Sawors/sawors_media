import 'package:flutter/material.dart';
import 'package:sawors_media_common/user.dart';

class UserIcon extends StatelessWidget {
  const UserIcon({super.key, required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    final iconData = user.profilePicture;
    print(iconData);
    final Widget displayWidget;
    if (iconData != null && iconData.path.isNotEmpty) {
      Widget tempWid;
      try {
        tempWid = Image.network(iconData.path);
      } catch (_) {
        tempWid = getDefaultProfilePicture();
      }
      displayWidget = tempWid;
    } else {
      displayWidget = getDefaultProfilePicture();
    }
    return displayWidget;
  }

  Widget getDefaultProfilePicture() {
    return CircleAvatar(child: Text(user.displayName[0].toUpperCase()));
  }
}
