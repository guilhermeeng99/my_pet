import 'package:flutter/material.dart';

import 'package:my_pet/app/theme/app_spacing.dart';

/// Page scaffold that locks the soft-sky background, edge padding, and
/// left-aligned title behavior so every screen feels part of the same shell.
///
/// Pass [body] for a single child or [slivers] for scrollable layouts.
class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    this.title,
    this.actions,
    this.leading,
    this.body,
    this.slivers,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.padding =
        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    this.titleSize = ScreenTitleSize.medium,
    super.key,
  }) : assert(
          body == null || slivers == null,
          'Provide either body or slivers, not both.',
        );

  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? body;
  final List<Widget>? slivers;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final ScreenTitleSize titleSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = switch (titleSize) {
      ScreenTitleSize.large => theme.textTheme.headlineLarge,
      ScreenTitleSize.medium => theme.textTheme.headlineSmall,
    };

    return Scaffold(
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      appBar: title == null && actions == null && leading == null
          ? null
          : AppBar(
              leading: leading,
              automaticallyImplyLeading: leading == null,
              title: title == null
                  ? null
                  : Text(title!, style: titleStyle),
              actions: actions,
            ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        top: title == null && leading == null && actions == null,
        // The AppShell renders the bottom nav as a floating pill with
        // `extendBody: true`, so content runs underneath the pill. Skip
        // the bottom safe area here and let scrollables consume the
        // remaining inset via `MediaQuery.viewPaddingOf(context).bottom`
        // — that's what lets the last list item rest just above the pill
        // instead of being hidden by it.
        bottom: false,
        child: Padding(
          padding: padding,
          child: slivers != null
              ? CustomScrollView(slivers: slivers!)
              : body ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

enum ScreenTitleSize { medium, large }
