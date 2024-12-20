// flourish.dart
import 'package:flourish_web/router.dart'; // Import the router configuration
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Flourish extends StatelessWidget {
  const Flourish({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flouria',
      routerConfig: createRouter(context),
    );
  }
}
