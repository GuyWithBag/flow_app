# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter analyze          # Lint (flutter_lints)
flutter test             # Run tests (test/ is currently empty)
flutter run              # Run in debug mode
flutter build apk        # Build Android
dart run build_runner build --delete-conflicting-outputs  # Regenerate barrel files
```

## Architecture

**Flow** is a Pomodoro timer app (Flutter) using **Provider + flutter_hooks** for state management.

### State Management
`lib/app.dart` sets up a `MultiProvider` with 5 core `ChangeNotifier` providers:
- `TimerProvider` — timer countdown logic (start/pause/reset, tick-based)
- `SessionProvider` — session history and focus-minute aggregation (mock Supabase data)
- `PresetProvider` — Pomodoro preset configs (Classic 25/5, Light 15/3, Heavy 45/10)
- `AuthProvider` — authentication state (mock; Supabase commented out)
- `ThemeProvider` — theme/color/background state persisted via `SharedPreferences`

Screens use `Provider.of<X>(context)` or `context.watch<X>()`. Complex screens (`timer_screen.dart`, `account_screen.dart`) are `HookWidget`s using `useRef`/`useState` for UI-only local state.

### Folder Conventions
```
lib/
  pages/       # Screens (one file per screen)
  providers/   # ChangeNotifier state (one file per domain)
  models/      # Data classes (timer_models.dart has TimerType, PomodoroPreset, Session, UserProfile)
  widgets/     # Reusable UI components
  painters/    # Custom Canvas painters (liquid wave, timer circle)
  shared/      # Enums and shared types
```

Each folder has a hand-written `<folder>.dart` barrel **and** a generated `<folder>.barrel.dart` from `barrel_generator`. Prefer importing from the barrel.

### Key Data Flow (Timer Screen)
`TimerScreen` (HookWidget) reads `TimerProvider`, `SessionProvider`, `PresetProvider`, and `ThemeProvider`. On timer completion it calls `SessionProvider.completeCurrentSession()`, plays a sound, then optionally auto-switches to break based on loop count.

### Per-Mode Theming
`ThemeProvider` supports separate color/background settings for `focus` and `breakTime` modes. Theme is applied via `ThemeProvider.getTimerModeTheme(TimerType)`.

## Incomplete / TODO Areas
- **Supabase** integration is stubbed in `main.dart` (commented out `Supabase.initialize`) and `SessionProvider` (mock data)
- **Notifications** — `NotificationService.initialize()` is a TODO in `main.dart`
- **Sound playback** — `TimerProvider` has `// TODO: Play start sound` / `// TODO: Play completion sound` comments
- **Auto-switch break logic** in `timer_provider.dart` is commented out (lines ~103–110)
- Dashboard charts (`fl_chart`) and `hive_local_storage` are added as dependencies but not yet wired up
