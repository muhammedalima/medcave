// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medcave/common/database/model/Ambulancerequest/ambulance_request_db.dart';
import 'package:medcave/config/colors/appcolor.dart';

class Buttonambulancesearch extends StatefulWidget {
  final VoidCallback onClick;

  const Buttonambulancesearch({
    required this.onClick,
    super.key,
  });

  @override
  State<Buttonambulancesearch> createState() => _ButtonambulancesearchState();
}

class _ButtonambulancesearchState extends State<Buttonambulancesearch> {
  final AmbulanceRequestDatabase _database = AmbulanceRequestDatabase();
  String buttonText = 'Request an ambulance';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadButtonText();
  }

  Future<void> _loadButtonText() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      // Get the latest request status using the modified method
      final statusData = await _database.getLatestRequestStatus();
      
      setState(() {
        buttonText = statusData['message'];
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading button text: $e');
      }
      // Set a user-friendly default if there's an error
      setState(() {
        buttonText = 'Request an ambulance';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : widget.onClick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLoading ? AppColor.primaryGreen.withOpacity(0.7) : AppColor.primaryGreen,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColor.secondaryGrey,
                  ),
                ),
              )
            : Text(
                buttonText,
                style: const TextStyle(
                  color: AppColor.secondaryGrey,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
      ),
    );
  }
}