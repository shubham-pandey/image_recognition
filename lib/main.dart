import 'package:final_task/pages/forgot.dart';
import 'package:final_task/pages/home_screen.dart';
import 'package:final_task/pages/login.dart';
import 'package:final_task/pages/signup.dart';
import 'package:final_task/pages/splash.dart';
import 'package:flutter/material.dart';

void main(){
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: LoginPage(),
    );
  }
}