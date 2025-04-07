import 'package:flutter/material.dart';
import 'package:medcave/config/colors/appcolor.dart';

class AlternativesLoadingWidget extends StatelessWidget {
  const AlternativesLoadingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Searching for alternatives...',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class NoAlternativesFoundWidget extends StatelessWidget {
  final bool isLoading;
  final String errorMessage;
  final VoidCallback onRetry;

  const NoAlternativesFoundWidget({
    Key? key,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No alternatives found for this medicine.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          if (!isLoading && errorMessage.isEmpty)
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}