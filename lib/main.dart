import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pet/app/bootstrap/app_bootstrap.dart';
import 'package:my_pet/app/di/injection_container.dart';
import 'package:my_pet/app/router/app_router.dart';
import 'package:my_pet/app/theme/app_theme.dart';
import 'package:my_pet/core/constants/app_constants.dart';
import 'package:my_pet/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pet/features/startup/presentation/cubit/startup_cubit.dart';
import 'package:my_pet/gen/strings.g.dart';

Future<void> main() async {
  await AppBootstrap.run();
  runApp(TranslationProvider(child: const MyPetApp()));
}

class MyPetApp extends StatefulWidget {
  const MyPetApp({super.key});

  @override
  State<MyPetApp> createState() => _MyPetAppState();
}

class _MyPetAppState extends State<MyPetApp> {
  late final AuthBloc _authBloc = sl<AuthBloc>();
  late final StartupCubit _startupCubit = sl<StartupCubit>();
  late final GoRouter _router = buildAppRouter(
    authBloc: _authBloc,
    startupCubit: _startupCubit,
  );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<StartupCubit>.value(value: _startupCubit),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        // Slang owns the active locale; mirror it on Material so
        // intl-aware widgets (date pickers, etc.) follow the same language.
        locale: TranslationProvider.of(context).flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: _router,
      ),
    );
  }
}
