# illustrations

Bundled mascot artwork.

- `cat_fullbody.png` — primary mascot. 3D-rendered friendly cat with a
  transparent background. Rendered through `PetMascot`
  (`lib/app/widgets/pet_mascot.dart`) wherever the app needs a
  pet-flavored hero image or empty-state placeholder: Welcome, Login,
  Startup, the Home greeting card, and the empty avatar slot on the Pet
  form and Emergency cards.

Add new illustrations here and consume them via the FlutterGen-generated
`Assets.illustrations.*` accessors (`lib/gen/assets.gen.dart`), wrapped in
a dedicated widget under `lib/app/widgets/` so call sites stay
design-system-only (no inline `Image.asset` paths leaking into feature code).
