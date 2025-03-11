import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:medcave/common/googlemapfunction/location_update.dart';
import 'package:medcave/config/theme/theme.dart';
import 'package:medcave/firebase_options.dart';
import 'package:medcave/Users/UserType/user_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  initializeBackgroundTasks();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedCave',
      theme: AppTheme.theme,
      home: const Userwrapper(),
    );
  }
}
