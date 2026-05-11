import 'package:flutter/material.dart';

/// Friendly cat mascot — renders the bundled 3D illustration at
/// `lib/app/assets/illustrations/cat_fullbody.png` centered inside a square slot.
///
/// `BoxFit.contain` keeps the artwork's proportions so the cat stays
/// itself at any size, and the same widget covers every surface where the
/// app wants a pet-flavored hero image: the Welcome / Login splash, the
/// Startup loading screen, the Home greeting card, and the empty-state
/// placeholder shown inside a pet's avatar slot before a photo is
/// uploaded. Surrounding containers (e.g. the tinted `primaryContainer`
/// rounded square on Pet form / Emergency / Greeting) provide the
/// backdrop — the mascot itself is transparent so it composes cleanly.
///
/// `cacheWidth`/`cacheHeight` resample on decode so we don't hold a
/// full-resolution texture in GPU memory just to display a 110-px avatar.
///
/// The illustration is decorative — surrounding screens carry the text
/// that conveys meaning, so we exclude it from semantics.
class PetMascot extends StatelessWidget {
  const PetMascot({this.size = 160, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheDim = (size * dpr).round();
    return ExcludeSemantics(
      child: Image.asset(
        'lib/app/assets/illustrations/cat_fullbody.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        cacheWidth: cacheDim,
        cacheHeight: cacheDim,
      ),
    );
  }
}
