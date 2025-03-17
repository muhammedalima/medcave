import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget that prevents the entire app from crashing when a rendering error occurs
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({super.key, required this.child});

  @override
  ErrorBoundaryState createState() => ErrorBoundaryState();
}

class ErrorBoundaryState extends State<ErrorBoundary> {
  bool hasError = false;
  dynamic error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset error state when dependencies change
    if (hasError) {
      setState(() {
        hasError = false;
        error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Something went wrong'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'An error occurred in the app.',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              if (kDebugMode) Text('Error: $error'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    hasError = false;
                    error = null;
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }

  void catchError(FlutterErrorDetails details) {
    if (kDebugMode) {
      print('Caught error in ErrorBoundary: ${details.exception}');
    }
    setState(() {
      hasError = true;
      error = details.exception;
    });
  }
}