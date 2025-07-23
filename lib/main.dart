import 'package:flutter/material.dart';
import 'package:statefulclickcounter/screen/log_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:statefulclickcounter/screen/firebase_options_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseConfig);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job Portal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginScreen(), // Use correct class name here
    );
  }
}
