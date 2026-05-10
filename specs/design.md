# Spec — Design System

## Goal

Define the visual language of my_pet: a friendly, calm, modern look that fits a "pet parent" app. The aesthetic is **inspired** by the FocaAI focus-app reference — vibrant blue primary, soft sky-blue background wash, oversized bold black headlines, generous whitespace, large pill-shaped buttons, soft white rounded cards with subtle shadows, friendly mascot illustration on welcome / home / empty states, minimalist 4-item bottom nav. We rebuild every asset (illustrations, icons, copy) ourselves; we mirror only the functional design decisions (tokens, hierarchy, spacing, button shapes), not any specific brand artwork or wording.

The system is implemented in `lib/app/theme/`. Widgets must consume these tokens via `Theme.of(context)` extensions — no hardcoded literals.

---

## Principles

1. **Calm > flashy.** Generous whitespace is part of the design, not waste.
2. **One bold thing per screen.** A single large headline or a single primary CTA — never both fighting for attention.
3. **Cards over boxes.** Content sits on white/dark cards with soft shadows on a tinted background; never on raw screen edges.
4. **Pills everywhere.** Buttons, tags, status indicators, and time pickers all use pill or strongly-rounded shapes.
5. **Mascot moments.** Illustrations and emoji are first-class citizens of empty states, onboarding, and success screens — keep them consistent in style.
6. **Color carries meaning.** Accent colors (success, warning, danger, info) are never decorative; they always communicate state.

---

## Color Tokens

All values defined in `lib/app/theme/app_colors.dart` as a const class. Do not reference hex literals from widgets.

### Brand

| Token              | Light       | Dark        | Use                                                  |
| ------------------ | ----------- | ----------- | ---------------------------------------------------- |
| `primary`          | `#2563EB`   | `#5B8DEF`   | Primary CTAs, headers, key accents                   |
| `primaryPressed`   | `#1D4ED8`   | `#2563EB`   | Pressed/hover state                                  |
| `primaryContainer` | `#E6EFFF`   | `#13234A`   | Tinted backgrounds, selected chips, badges           |
| `onPrimary`        | `#FFFFFF`   | `#FFFFFF`   | Text/icons on `primary`                              |
| `onPrimaryContainer` | `#0B2A6B` | `#CFE0FF`   | Text/icons on `primaryContainer`                     |

### Neutral surfaces

| Token              | Light       | Dark        | Use                                                  |
| ------------------ | ----------- | ----------- | ---------------------------------------------------- |
| `background`       | `#F2F7FF`   | `#0B1220`   | Scaffold background (soft sky wash)                  |
| `surface`          | `#FFFFFF`   | `#131C30`   | Cards, sheets, dialogs                               |
| `surfaceMuted`     | `#EAF2FF`   | `#1B2540`   | Inset cards, list zebra, disabled fields             |
| `outline`          | `#DDE6F4`   | `#2D3957`   | Borders, dividers                                    |
| `onBackground`     | `#0E1830`   | `#EDF2FF`   | Primary text on background                           |
| `onSurface`        | `#0E1830`   | `#EDF2FF`   | Primary text on surface                              |
| `onSurfaceMuted`   | `#5C6985`   | `#A5B0C9`   | Secondary text                                       |
| `onSurfaceFaint`   | `#8E99B3`   | `#7480A0`   | Tertiary text, placeholders                          |

### Semantic

| Token       | Light       | Dark        | Meaning                                              |
| ----------- | ----------- | ----------- | ---------------------------------------------------- |
| `success`   | `#3FBF7F`   | `#5FD89A`   | "Up to date", "saved", confirmations                 |
| `warning`   | `#F5B544`   | `#FFC966`   | "Due soon", soft alerts                              |
| `danger`    | `#F25A4F`   | `#FF7A6E`   | "Overdue", destructive actions, errors               |
| `info`      | `#3FA9F5`   | `#5FBEFF`   | Neutral informational badges                         |

### Pet category accents

Used to color-code species and as palette for empty-state illustrations. Pure decoration.

| Token        | Hex         |
| ------------ | ----------- |
| `accentCat`  | `#FF8C73`   |
| `accentDog`  | `#FFB84D`   |
| `accentBird` | `#5FBEFF`   |
| `accentRabbit` | `#7C8CFF` |
| `accentOther` | `#7AC4A8`  |

---

## Typography

Defined in `lib/app/theme/app_typography.dart`. Font family: **Inter** (variable weights), loaded via `google_fonts` for the MVP and bundled later.

| Style          | Size | Weight | Line height | Letter spacing | Use                              |
| -------------- | ---- | ------ | ----------- | -------------- | -------------------------------- |
| `display`      | 36   | 700    | 1.1         | -0.5           | Hero numbers (rare)              |
| `headlineXL`   | 28   | 700    | 1.15        | -0.4           | Page titles in onboarding flows  |
| `headlineL`    | 24   | 700    | 1.2         | -0.3           | Page titles                      |
| `headlineM`    | 20   | 600    | 1.25        | -0.2           | Section headers                  |
| `titleL`       | 18   | 600    | 1.3         | 0              | Card titles                      |
| `titleM`       | 16   | 600    | 1.35        | 0              | List item primary text           |
| `bodyL`        | 16   | 400    | 1.5         | 0              | Default body                     |
| `bodyM`        | 14   | 400    | 1.5         | 0.1            | Secondary body, captions         |
| `label`        | 13   | 600    | 1.3         | 0.4            | Pill labels, tab text            |
| `caption`      | 12   | 500    | 1.3         | 0.5            | Helper text, metadata            |
| `overline`     | 11   | 700    | 1.2         | 1.2 (UPPER)    | "TODAY", "DUE SOON" tags         |

Headlines use **bold (700)** weight; body stays at 400. Avoid italics.

---

## Spacing

Strict 4-pt grid. Defined in `lib/app/theme/app_spacing.dart` as a const class:

| Token   | px  | Use                                   |
| ------- | --- | ------------------------------------- |
| `xxs`   | 4   | Inside chip padding                   |
| `xs`    | 8   | Icon + label gap                      |
| `sm`    | 12  | Inside small card padding             |
| `md`    | 16  | Default screen edge padding           |
| `lg`    | 24  | Section gaps                          |
| `xl`    | 32  | Headline → content gap                |
| `xxl`   | 48  | Top of onboarding screens             |
| `huge`  | 64  | Empty state vertical centering        |

Default screen horizontal padding: `md` (16). Default vertical between unrelated sections: `lg` (24).

---

## Radii

| Token       | px  | Use                                    |
| ----------- | --- | -------------------------------------- |
| `radiusSm`  | 8   | Small chips, inputs                    |
| `radiusMd`  | 12  | Cards (default)                        |
| `radiusLg`  | 16  | Large buttons, hero cards              |
| `radiusXL`  | 24  | Bottom sheets (top-only), illustrations frame |
| `radiusPill`| 999 | Pill buttons, tags, status badges      |

---

## Elevation / shadow

Soft shadows only — no harsh black drop shadows.

```dart
// app_shadows.dart — ink shifted to navy-black so depth reads naturally on the sky-blue ground.
static const elevation1 = [BoxShadow(color: Color(0x0F0B1B3A), blurRadius: 8,  offset: Offset(0, 2))];
static const elevation2 = [BoxShadow(color: Color(0x140B1B3A), blurRadius: 16, offset: Offset(0, 4))];
static const elevation3 = [BoxShadow(color: Color(0x1A0B1B3A), blurRadius: 24, offset: Offset(0, 8))];
```

| Token        | Use                                                  |
| ------------ | ---------------------------------------------------- |
| `elevation1` | Resting cards                                        |
| `elevation2` | Floating cards, active list rows                     |
| `elevation3` | FABs, bottom sheets, modals                          |

In dark mode, opacities are tripled and color-shifted toward `#000000`.

---

## Components

### Primary button

- Shape: pill (`radiusPill`) — full width by default in mobile
- Height: 56 (large), 44 (medium), 36 (small)
- Background: `primary`; pressed → `primaryPressed`
- Label: `titleM` weight 600, color `onPrimary`
- Optional leading icon: 20px, same color as label, gap 8

### Secondary button

- Same shape, height
- Background: transparent; border 1.5px in `primary`
- Label color: `primary`

### Tertiary / text button

- No background, no border
- Label color: `primary`, underline on press

### Card

- Background: `surface`
- Radius: `radiusMd`
- Padding: `md` (16) all around
- Shadow: `elevation1`
- Optional border 1px in `outline` for borderless designs

### Pill / chip

- Height: 32 (compact), 40 (selectable)
- Background: `surfaceMuted` unselected, `primaryContainer` selected
- Label: `label` style, color `onSurface` / `onPrimaryContainer`
- Radius: `radiusPill`
- Tap target: at least 40 vertical

### Status badge

| Status   | Background                | Foreground            | Example label   |
| -------- | ------------------------- | --------------------- | --------------- |
| Up to date | `success` @ 15% opacity  | `success`             | "UP TO DATE"    |
| Due soon | `warning` @ 15% opacity   | `#8A6520`             | "DUE IN 5 DAYS" |
| Overdue  | `danger` @ 15% opacity    | `danger`              | "OVERDUE"       |

Use `overline` typography. Padding 6 vertical / 12 horizontal. Pill shape.

### Bottom sheet

- Background: `surface`
- Top corners: `radiusXL`
- Drag handle: 4×40 rounded `outline`, top center, 12px from edge
- Padding: `lg` horizontal, `md` top, safe area inset bottom
- Shadow: `elevation3`

### Input field

- Height: 56
- Radius: `radiusMd`
- Background: `surfaceMuted` (filled style — outlined disliked here)
- Border: none in resting; 2px `primary` on focus
- Label floats above when filled; placeholder `onSurfaceFaint`

### App bar

- Background: matches scaffold (`background`) — no elevation in default
- Title: `headlineM`, left-aligned (NOT centered) — Ahead-style
- Leading: 24px icon, tap target 48
- Trailing: at most 2 actions

### Bottom nav

- 4 items: Home, Reminders, Stats, Profile
- Active item: filled icon variant (`PhosphorIconsFill.*`) tinted `primary`, label colored `primary` and weighted 700
- Inactive item: outline icon variant (`PhosphorIconsRegular.*`) tinted `onSurfaceFaint`, label tinted `onSurfaceMuted` weight 600
- **No pill behind active item** — the active state is communicated only by color + weight + filled glyph (matches reference)
- Background: `surface`; height 64 + safe-area inset bottom; soft `elevation2` shadow
- Implementation lives in `lib/app/widgets/app_bottom_nav.dart`; consumed by the [`StatefulShellRoute`](#shell-and-tabs) in `lib/app/router/app_shell.dart`

---

## Shared widgets (`lib/app/widgets/`)

The design system ships a small catalog of token-only widgets. Every page must compose these instead of building one-off Material widgets, so radius / shadow / padding / typography stay consistent.

| Widget               | Purpose                                                              |
| -------------------- | -------------------------------------------------------------------- |
| `ScreenScaffold`     | Page shell — soft-sky background, edge padding, optional left-aligned title |
| `AppCard`            | Soft white rounded surface (`radiusLg`, `elevation1`), optional `onTap` |
| `AppPrimaryButton`   | Pill `FilledButton` with optional leading icon, three sizes, built-in loading |
| `AppSecondaryButton` | Pill outlined counterpart for secondary actions                      |
| `AppBottomNav`       | 4-item minimalist nav (filled vs. outline icons, no pill, see above) |
| `GreetingCard`       | Hero card on Home: greeting headline + mascot peek                   |
| `StatCard`           | Compact stat (icon + label + value), designed to live in 2-up Row    |
| `FeatureListCard`    | Tinted-icon row with title + subtitle + chevron, used for nav and CTA empty states |
| `SectionHeader`      | Bold left-aligned section title with optional trailing chevron       |
| `StatusBadge`        | Pill badge tinted by `StatusTone` (success / warning / danger / info / neutral) |
| `PetMascot`          | Programmatic placeholder cat-face mascot (CustomPaint), no asset dependency |

The mascot will be replaced with a commissioned illustration shipped at `assets/illustrations/mascot.svg`. Until then, the placeholder renders the same friendly silhouette using primary tokens.

## Shell and tabs

Authenticated tabs (Home / Reminders / Stats / Profile) live behind a `StatefulShellRoute.indexedStack` in `lib/app/router/app_router.dart`, wrapped by `AppShell` (`lib/app/router/app_shell.dart`). Each tab keeps its own navigator stack — pet detail / vaccinations sub-routes never leak across tab switches. Auth-only routes (`/`, `/welcome`, `/login`) live outside the shell.

## Iconography

- Set: **Phosphor Icons** (`phosphor_flutter`) — friendlier than Material Icons, matches the soft aesthetic. Default style: `regular` (24px stroke 1.5).
- Use `bold` (`fill`) variant only for active bottom nav items.
- Pet species icons are custom illustrations (paw stylized) — not from Phosphor.

---

## Illustrations

- Style guide: flat, rounded, 2–3 colors max per illustration, no gradients except subtle background washes.
- Source: hand-drawn or commissioned originals stored in `assets/illustrations/` as SVG.
- Empty states must include an illustration; loading states must not (use a `Skeleton` placeholder instead).
- Mascot for empty states / onboarding: undefined — to be designed; spec a generic friendly cat silhouette as placeholder.
- We do NOT use Ahead's mascot or any third-party illustration without a license.

---

## Motion

- Durations: 150ms (micro), 250ms (default), 400ms (page transition)
- Curves: `Curves.easeOutCubic` for entries, `Curves.easeInCubic` for exits
- Page transitions: shared-axis horizontal (use `flutter_animate` or built-in)
- Bottom sheets: spring damping 0.85
- No scaling on tap of regular buttons; do scale (0.96) on cards used as primary actions

---

## Dark mode

All tokens are pre-defined for dark in the tables above. The dark surface is **deep navy** (`#0B1220`) — not pure black — to keep the brand cohesive with the daylight blue palette. Cards lift to `#131C30`. Shadows become more pronounced (3× alpha) to keep depth visible against the darker background.

---

## Accessibility

- Minimum text contrast: 4.5:1 body, 3:1 large headlines (`headlineL+`)
- Minimum touch target: 44×44 (iOS) / 48×48 (Android)
- All interactive elements expose `Semantics` labels
- Status colors never carry meaning alone — always paired with text/icon
- Respect system text scaling up to 200%

---

## Theme implementation

```dart
// lib/app/theme/app_theme.dart
class AppTheme {
  static ThemeData light() => ThemeData(
        useMaterial3: true,
        colorScheme: AppColors.lightScheme,
        textTheme: AppTypography.textTheme(brightness: Brightness.light),
        // ...component themes derived from tokens
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        colorScheme: AppColors.darkScheme,
        textTheme: AppTypography.textTheme(brightness: Brightness.dark),
        // ...
      );
}
```

Custom tokens not covered by `ColorScheme` (e.g. `surfaceMuted`, `accentCat`) live in a `ThemeExtension`:

```dart
extension AppColorsX on ColorScheme {
  Color get surfaceMuted => /* ... */;
  Color get success => /* ... */;
  // etc.
}
```

Or via `Theme.of(context).extension<AppPalette>()!`.

---

## Folder layout

```
lib/app/theme/
├── app_theme.dart          # ThemeData light/dark factory
├── app_colors.dart         # Color tokens (light + dark)
├── app_typography.dart     # TextStyle tokens + textTheme builder
├── app_spacing.dart        # Const doubles for the 4pt grid
├── app_radii.dart          # BorderRadius tokens
├── app_shadows.dart        # BoxShadow lists
└── app_palette_ext.dart    # ThemeExtension for non-Material tokens
```

---

## What to verify on every UI change

1. Uses tokens from `lib/app/theme/`? (no inline hex, no inline radius, no inline TextStyle)
2. Tested in both light and dark themes?
3. Touch targets ≥ 44pt?
4. Text readable at 200% scale?
5. Consistent padding multiples of 4?
6. If new component invented — added to this doc and to a Storybook page (Phase 4)?
