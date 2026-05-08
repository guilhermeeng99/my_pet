import 'package:flutter/material.dart';

import 'package:my_pet/app/bootstrap/app_bootstrap.dart';
import 'package:my_pet/app/router/app_router.dart';
import 'package:my_pet/app/theme/app_theme.dart';
import 'package:my_pet/core/constants/app_constants.dart';

Future<void> main() async {
  await AppBootstrap.run();
  runApp(const MyPetApp());
}

class MyPetApp extends StatelessWidget {
  const MyPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: buildAppRouter(),
    );
  }
}
