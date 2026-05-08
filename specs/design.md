# Spec — Design System

## Goal

Define the visual language of my_pet: a friendly, calm, modern look that fits a "pet parent" app. The aesthetic is **inspired** by the Ahead app — vibrant purple primary, oversized bold headlines, generous whitespace, large pill-shaped buttons, soft pastel accents, friendly illustrations. We rebuild every asset (illustrations, icons, copy) ourselves; we mirror only the functional design decisions (tokens, hierarchy, spacing, button shapes), not any specific brand artwork or wording.

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
| `primary`          | `#6B55FF`   | `#8C7BFF`   | Primary CTAs, headers, key accents                   |
| `primaryPressed`   | `#4D3DD9`   | `#6B55FF`   | Pressed/hover state                                  |
| `primaryContainer` | `#EFECFF`   | `#2A2348`   | Tinted backgrounds, selected chips, badges           |
| `onPrimary`        | `#FFFFFF`   | `#FFFFFF`   | Text/icons on `primary`                              |
| `onPrimaryContainer` | `#2A2070` | `#D9D2FF`   | Text/icons on `primaryContainer`                     |

### Neutral surfaces

| Token              | Light       | Dark        | Use                                                  |
| ------------------ | ----------- | ----------- | ---------------------------------------------------- |
| `background`       | `#F7F6FB`   | `#0F0E1A`   | Scaffold background (subtle lavender tint)           |
| `surface`          | `#FFFFFF`   | `#1C1A2E`   | Cards, sheets, dialogs                               |
| `surfaceMuted`     | `#F1EFF7`   | `#252338`   | Inset cards, list zebra, disabled fields             |
| `outline`          | `#E5E1F0`   | `#3A3654`   | Borders, dividers                                    |
| `onBackground`     | `#1A1626`   | `#F2EFFF`   | Primary text on background                           |
| `onSurface`        | `#1A1626`   | `#F2EFFF`   | Primary text on surface                              |
| `onSurfaceMuted`   | `#6B6580`   | `#A29CC0`   | Secondary text                                       |
| `onSurfaceFaint`   | `#9A93B0`   | `#7A7596`   | Tertiary text, placeholders                          |

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
| `accentRabbit` | `#A685FF` |
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
// app_shadows.dart
static const elevation1 = [BoxShadow(color: Color(0x0F1A1626), blurRadius: 8,  offset: Offset(0, 2))];
static const elevation2 = [BoxShadow(color: Color(0x141A1626), blurRadius: 16, offset: Offset(0, 4))];
static const elevation3 = [BoxShadow(color: Color(0x1A1A1626), blurRadius: 24, offset: Offset(0, 8))];
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

- 4 items maximum (Home, Health, Reminders, Profile)
- Active item: `primary` icon + `label` style label
- Inactive: `onSurfaceFaint` icon, no label OR small label
- Pill background behind active item: `primaryContainer`, `radiusPill`

---

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

All tokens are pre-defined for dark in the tables above. The dark surface is **deep purple-black** (`#0F0E1A`) — not pure black — to keep the brand warm. Cards lift to `#1C1A2E`. Shadows become more pronounced (3× alpha) to keep depth visible against the darker background.

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
