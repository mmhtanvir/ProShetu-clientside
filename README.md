# ProShetu — Flutter Frontend

Offline-first crisis communication platform. Dark-first, low-end-device
optimized, Clean Architecture.

## Run

```
flutter pub get
flutter gen-l10n
flutter run \
  --dart-define=API_BASE_URL=https://your-api.example \
  --dart-define=WS_BASE_URL=wss://your-ws.example
```

## Structure

- `lib/app` — composition root: app widget, router, DI, theme + tokens
- `lib/core` — cross-cutting: constants, errors, Result, responsive utils, shared widgets
- `lib/infrastructure` — crypto / storage / transport / mesh / sync / media / platform / notifications (interfaces-first)
- `lib/features/<feature>` — `data / domain / presentation{controllers,screens,widgets,providers}`
- `lib/l10n` — ARB files (en, bn)

## Conventions

- No hardcoded colors, spacing, radii, or endpoints — tokens and `AppConfig` only.
- Riverpod for state; GoRouter for navigation; screens navigate by route *name*.
- Fonts must be bundled; runtime font fetching is disabled (offline-first).
