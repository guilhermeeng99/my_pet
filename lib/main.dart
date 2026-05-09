import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:my_pet/app/bootstrap/app_bootstrap.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/router/app_router.dart';
import 'package:my_pet/app/theme/app_theme.dart';
import 'package:my_pet/core/constants/app_constants.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';

Future<void> main() async {
  await AppBootstrap.run();
  runApp(const MyPetApp());
}

class MyPetApp extends StatefulWidget {
  const MyPetApp({super.key});

  @override
  State<MyPetApp> createState() => _MyPetAppState();
}

class _MyPetAppState extends State<MyPetApp> {
  late final AuthBloc _authBloc = sl<AuthBloc>();
  late final GoRouter _router = buildAppRouter(_authBloc);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: _router,
      ),
    );
  }
}
