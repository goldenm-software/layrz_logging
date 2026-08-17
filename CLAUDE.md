# layrz_logging

A thin logging wrapper for Flutter applications. The package emits log entries; it does
**not** store them. Persistence is the consuming application's concern — subscribe to
`Log.stream` and store entries yourself.

## Versioning and releases

**The version in `pubspec.yaml` is self-managed. CI never writes it.**

No workflow patches, injects, or rewrites the `version:` field — there is no `sed`, `yq`,
or `pub version` step anywhere in `.github/workflows/`. The version is committed by hand
and CI simply trusts whatever is in the file.

`.github/workflows/publish.yaml` triggers on a tag matching `v[0-9]+.[0-9]+.[0-9]+` and
runs `flutter pub publish --force` against the committed version. Two consequences:

- **The pubspec version and the git tag must agree.** Nothing validates this for you; a
  mismatch publishes the wrong version to pub.dev.
- **Creating the tag *is* publishing.** There is no separate release approval step, so
  never push a `v*` tag as a routine step — only when the release is meant to go public.

Release order: bump `version:` in `pubspec.yaml` → prepend a `## <version>` section to
`CHANGELOG.md` → commit → merge `development` into `main` → tag `v<version>` on `main`.

The `/prepare-release` skill handles everything up to the tag.

## Commands

```sh
make check      # analyze, then test with coverage — run this before pushing
make test       # flutter test --coverage, prints the coverage percentage
make coverage   # depends on test; strips coverage:ignore markers, then reports
make analyze    # flutter analyze
```

## Coverage gate

`.github/workflows/checks.yaml` enforces a **90%** line-coverage threshold on PRs to
`main` via `goldenm-software/layrz-actions`. The suite currently covers 100% (61/61
lines), so there is headroom — but the gate is real and will fail a PR that regresses.

Note: a line whose condition is entirely compile-time constants (e.g.
`if (kDebugMode || isWeb) {` on its own line) is constant-folded and can *never* be
covered — it records `DA:<line>,0` while counting toward `LF`. Keep such guards on the
same physical line as a real call so the branch stays attributable.

## Layout

```
lib/layrz_logging.dart   # exports only: src/log.dart, entry.dart, level.dart, ansi_colors.dart
lib/src/log.dart         # the Log class: ensureInitialized, stream, log, level helpers
lib/src/entry.dart       # LogEntry (message, level, timestamp, optional error/stackTrace)
lib/src/level.dart       # LogLevel enum with toString() and ANSI color
lib/src/ansi_colors.dart # AnsiColor constants
```

## Conventions

- Console output goes through `debugPrint`, never `dart:developer`'s `log()` — the latter
  is an unimplemented no-op on both JS and wasm, and `flutter_tools` does not listen to
  the VM-service `Logging` stream, so it is invisible in tests, in `flutter run`, and on
  web.
- `Log.ensureInitialized()` permanently replaces the global `FlutterError.onError` and
  `PlatformDispatcher.instance.onError`. Tests must save and restore both.
- Pass diagnostics as `error:`/`stackTrace:` arguments; never concatenate a stack trace
  into a log message.
- Tests that log but do not assert on console output should install
  `test/helpers/capture_debug_print.dart` so the test run stays quiet.
