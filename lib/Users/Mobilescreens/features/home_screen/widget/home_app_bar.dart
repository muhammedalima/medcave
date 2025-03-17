import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:medcave/Users/Mobilescreens/features/notification/notifications.dart';
import 'package:medcave/config/colors/appcolor.dart';
import 'package:medcave/config/fonts/font.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Color backgroundColor;
  final String userName;

  const HomeAppBar({
    super.key,
    this.backgroundColor = AppColor.secondaryBackgroundWhite,
    this.userName = "John", // Default name that can be overridden
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
      child: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(0.0),
          child: GestureDetector(
            onTap: () {
              _showWelcomePopup(context);
            },
            child: CircleAvatar(
              radius: 32,
              backgroundColor: AppColor.navigationBackColor,
              child: SvgPicture.asset(
                'assets/vectors/logo.svg',
                width: 32,
                height: 32,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(0.0),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: AppColor.navigationBackColor,
              child: IconButton(
                icon: const Icon(
                  Icons.notifications,
                  color: Colors.black,
                  size: 32,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWelcomePopup(BuildContext context) {
    showDialog(
      barrierColor: Color.fromARGB(169, 111, 179, 210),
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: AppColor.primaryBlue,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top greeting section
                Text(
                  "Hey, $userName",
                  style: FontStyles.heading,
                ),
                const SizedBox(height: 8),
                Text(
                  "you are using MedCave an smart health solution",
                  style: FontStyles.subHeading
                      .copyWith(color: AppColor.secondaryGrey),
                ),
                const SizedBox(height: 60),

                // Middle section with main message
                Center(
                  child: Text(
                    "We Run\nHealthcare,\nYou Run The\nWorld",
                    textAlign: TextAlign.center,
                    style: FontStyles.titlePage,
                  ),
                ),
                const SizedBox(height: 60),

                // Footer section with credits
                Center(
                  child: Column(
                    children: [
                      Text(
                        "DESIGNED AND DEVELOPED BY",
                        style: FontStyles.bodyEmphasis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Aleena . Nandana A S . Nandana V S . Muhammed Ali",
                        style: FontStyles.bodySmall
                            .copyWith(color: AppColor.secondaryGrey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);
}
