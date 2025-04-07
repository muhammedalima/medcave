import 'package:flutter/material.dart';
import 'package:medcave/config/colors/appcolor.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final IconData? rightIcon;
  final VoidCallback? onRightPressed;
  final String? customTitle;

  const CustomAppBar({
    super.key,
    this.customTitle,
    this.icon = Icons.arrow_back,
    required this.onPressed,
    this.backgroundColor = Colors.transparent,
    this.rightIcon,
    this.onRightPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
      child: AppBar(
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: customTitle != null ? Text(customTitle!) : null,
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(0.0),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: AppColor.navigationBackColor,
            child: IconButton(
              icon: Icon(
                icon,
                size: 32,
                color: const Color(0xff666666),
              ),
              onPressed: onPressed,
            ),
          ),
        ),
        actions: rightIcon != null
            ? [
                Padding(
                  padding: const EdgeInsets.all(0.0),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColor.navigationBackColor,
                    child: IconButton(
                      icon: Icon(
                        rightIcon,
                        color: const Color(0xff666666),
                        size: 32,
                      ),
                      onPressed: onRightPressed,
                    ),
                  ),
                ),
              ]
            : null,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);
}
