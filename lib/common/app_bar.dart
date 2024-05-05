import 'package:flutter/material.dart';

class SuperSetAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;

  const SuperSetAppBar({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
